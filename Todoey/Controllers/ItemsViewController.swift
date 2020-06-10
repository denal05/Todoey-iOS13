//
//  ItemsViewController.swift
//  Todoey
//
//  Originally created by Philipp Muellauer on 02/12/2019.
//  Adapted by Denis Aleksandrov on 2020-04-25.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
#if CoreData
import CoreData
#elseif Realm
import RealmSwift
import ChameleonFramework
#endif

class ItemsViewController: SwipeTableViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    
    #if CoreData
    var itemArray = [Item]()
    var selectedCategory: `Category`? {
        didSet {
            loadItems()
        }
    }
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    #elseif Realm
    let realm = try! Realm()
    var results = try! Realm().objects(RealmItem.self).sorted(byKeyPath: "dateCreated")
    var notificationToken: NotificationToken?
    
    // Compiler Error: Expected member name or constructor call after type name
    //var items = Results<RealmItem>?

    var selectedCategory: RealmCategory? {
        didSet {
            // loadItems() was previously called here, but in Realm Swift 4.4.1+ it's replaced with results.observe
            results = selectedCategory!.items.sorted(byKeyPath: "title", ascending: true)
            tableView.reloadData()
        }
    }
    #else
    var itemArray = [PListItem]()
    #endif
    
    //var userDefaults = UserDefaults.standard
    let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Items.plist")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //searchBar.delegate = self
        
        #if CoreData
        loadItems()
        #elseif Realm
        observeRealmResultsAndUpdateTableView()
        tableView.separatorStyle = .none
        #else
        print("ItemsViewController::" + #function + " => ")
        print(dataFilePath)
        loadItems()
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        title = selectedCategory!.name
        if let catBgColourHexString = selectedCategory?.colour {
            guard let navBar = navigationController?.navigationBar else {fatalError(#function + " => Navigation Controller Does Not Exist Right Now")}
            if let navBarColour = UIColor(hexString: catBgColourHexString) {
                navBar.backgroundColor = navBarColour
                navBar.tintColor = ContrastColorOf(navBar.backgroundColor!, returnFlat: true)
                navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: ContrastColorOf(navBarColour, returnFlat: true)]
                searchBar.barTintColor = navBarColour
            }
        }
    }
    
    //MARK: - Tableview Datasource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        #if CoreData
        return itemArray.count
        #elseif Realm
        return results.count
        #else
        // #TODO Implement categories for target PList
        return 0
        #endif
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        #if CoreData
        let item = itemArray[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = item.done ? .checkmark : .none
        #elseif Realm
        // Override cell for target Realm by calling super
        cell = super.tableView(tableView, cellForRowAt: indexPath)
        let item = results[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType   = item.done ? .checkmark : .none
        cell.backgroundColor = UIColor(hexString: selectedCategory!.colour)?.darken(byPercentage: CGFloat(indexPath.row) / CGFloat(results.count))
        cell.textLabel?.textColor = ContrastColorOf(cell.backgroundColor!, returnFlat: true)
        #else
        #endif
        
        return cell
    }
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        #if CoreData
        // An example of Updating the itemArray and then saveItems() to DB:
        //itemArray[indexPath.row].setValue("Completed!", forKey: "title")
        
        // An example of Deleting an Item from DB and removing it from the itemArray:
        //context.delete(itemArray[indexPath.row])
        //itemArray.remove(at: indexPath.row)
        #elseif Realm
        // Compiler Error: Expected member name or constructor call after type name
        //items?[indexPath.row].done = !items?[indexPath.row].done
        
        do {
            try realm.write {
                let item = results[indexPath.row]
                item.done = !item.done
                
                // An example of Deleting in Realm:
                //realm.delete(itemArray[indexPath.row])
            }
        } catch {
            print("Error writing and adding Item to Realm: \(error)")
        }
        
        tableView.reloadData()
        #else
        itemArray[indexPath.row].done = !itemArray[indexPath.row].done
        #endif
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Add New Items
    
    @IBAction @objc func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Todoey Item", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            #if CoreData
            let newItem = Item(context: self.context)
            newItem.parentCategory = self.selectedCategory
            newItem.title = textField.text!
            newItem.done = false
            self.itemArray.append(newItem)
            self.saveItems()
            #elseif Realm
            if let currentCategory = self.selectedCategory {
                print("ItemsViewController::" + #function + " => selectedCategory is " + currentCategory.name)
                do {
                    let newItem = RealmItem()
                    newItem.title = textField.text!
                    newItem.dateCreated = Date()
                    
                    self.realm.beginWrite()
                    // https://stackoverflow.com/questions/37355078/what-is-the-difference-between-add-and-create
                    //self.realm.create(RealmItem.self, value: [textField.text!, Date(), ])
                    self.realm.add(newItem)
                    currentCategory.items.append(newItem)
                    try! self.realm.commitWrite()
                    
                    // Updating the tableView by inserting, deleting or reloading rows fixes "NSInternalInconsistencyException, reason: Invalid update: invalid number of rows in section 0."
                    self.observeRealmResultsAndUpdateTableView()                    
                } catch {
                    print("Error writing and adding Item to Realm: \(error)")
                }
            } else {
                print("ItemsViewController::" + #function + " => self.selectedCategory is null, so cannot realm.write the newItem!")
            }

            #else
            let newItem = PListItem()
            newItem.title = textField.text!
            newItem.done = false
            self.itemArray.append(newItem)
            self.saveItems()
            #endif
            
            self.tableView.reloadData()
        }
        
        alert.addTextField { (tempAlertTextField) in
            tempAlertTextField.placeholder = "Write your new item here"
            textField = tempAlertTextField
        }
        
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
        tableView.reloadData()
    }
    
    #if CoreData
    func saveItems() {
        do {
            try context.save()
        } catch {
            print("Error saving context and Creating item in DB: \(error)")
        }
        tableView.reloadData()
    }
    #elseif Realm
    // No need for saveItem() in Realm Swift 4.4.1+
    #else
    func saveItems() {
        let encoder = PropertyListEncoder()
        do {
            let data = try encoder.encode(itemArray)
            try data.write(to: dataFilePath!)
        } catch {
            print("Error encoding item array: \(error)")
        }
        tableView.reloadData()
    }
    #endif
    
    #if CoreData
    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), and predicate: NSPredicate? = nil) {
        do {
            // 'NSInvalidArgumentException', reason: 'Unable to parse the format string "parentCategory.name MATCHED %@"'
            //let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHED %@", selectedCategory!.name!)
            let categoryPredicate = NSPredicate(format: "parentCategory.name = %@", selectedCategory!.name!)
            
            if let additionalPredicate = predicate {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, additionalPredicate])
            } else {
                request.predicate = categoryPredicate
            }
        
            itemArray = try context.fetch(request)
        } catch {
            print("Error fetching from context and Reading item from DB: \(error)")
        }
        tableView.reloadData()
    }
    #elseif Realm
    // loadItems() in Realm Swift 4.4.1+ is replaced with results.observe
    
    override func updateModel(at indexPath: IndexPath) {
        let itemForDeletion = self.results[indexPath.row]
        self.realm.beginWrite()
        self.realm.delete(itemForDeletion)
        try! self.realm.commitWrite()
        observeRealmResultsAndUpdateTableView()
    }
    
    func observeRealmResultsAndUpdateTableView() {
        // Set results notification block
        self.notificationToken = results.observe { (changes: RealmCollectionChange) in
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                self.tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the TableView
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                
                // https://stackoverflow.com/a/60367346/4669096
                /* Calling tableView.reloadRows() here seems to cause the
                 [TableView] Warning: "UITableView was told to layout its
                 visible cells and other contents without being in the view
                 hierarchy (the table view or one of its superviews has not been
                 added to a window). This may cause bugs by forcing views inside
                 the table view to load and perform layout without accurate
                 information (e.g. table view bounds, trait collection, layout
                 margins, safe area insets, etc), and will also cause
                 unnecessary performance overhead due to extra layout passes.
                 Make a symbolic breakpoint at
                 UITableViewAlertForLayoutOutsideViewHierarchy to catch this in
                 the debugger and see what caused this to occur, so you can
                 avoid this action altogether if possible, or defer it until the
                 table view has been added to a window."
                */
                self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.tableView.endUpdates()
            case .error(let err):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(err)")
            }
        }
    }
    #else
    func loadItems() {
        if let safeData = try? Data(contentsOf: dataFilePath!) {
            let decoder = PropertyListDecoder()
            do {
                itemArray = try decoder.decode([PListItem].self, from: safeData)
            } catch {
                print("Error decoding item array: \(error)")
            }
        }
        tableView.reloadData()
    }
    #endif
}

//MARK: - Search Bar Methods
extension ItemsViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        #if CoreData
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
        // Next, we're going to give an array with a single item back to request.sortDescriptors
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        loadItems(with: request, and: predicate)
        #elseif Realm
        results = selectedCategory!.items.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "dateCreated", ascending: false)
        tableView.reloadData()
        #else
        #endif
        
        print(#function + " => \"" + searchBar.text! + "\"")
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            #if Realm
            results = selectedCategory!.items.sorted(byKeyPath: "title", ascending: true)
            #endif
            tableView.reloadData()
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
}
