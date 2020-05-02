//
//  ViewController.swift
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
#endif

// #TODO Refactor class from TodoListViewController into ItemsViewController
// Main.storyboard > TableView > ID > Custom Class: ItemsViewController
class TodoListViewController: UITableViewController {
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
    
    // Compiler Error: Expected member name or constructor call after type name
    //var items = Results<RealmItem>?
    var itemArray = [RealmItem]()
    var selectedCategory: RealmCategory? {
        didSet {
            loadItems()
        }
    }
    #else
    var itemArray = [ItemPList]()
    
    //let newItem1 = ItemPList()
    //newItem1.title = "First"
    //itemArray.append(newItem1)
    //
    //let newItem2 = ItemPList()
    //newItem2.title = "Second"
    //itemArray.append(newItem2)
    //
    //let newItem3 = ItemPList()
    //newItem3.title = "Third"
    //itemArray.append(newItem3)
    #endif
    
    //var userDefaults = UserDefaults.standard
    let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Items.plist")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //searchBar.delegate = self
        
        #if CoreData
        loadItems()
        #elseif Realm
        // loadItems() is already being called in declaration of selectedCategory
        #else
        print("TodoListViewController::" + #function + " => ")
        print(dataFilePath)
        loadItems()
        #endif
    }
    
    //MARK: - Tableview Datasource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        #if CoreData
        return itemArray.count
        #elseif Realm
        //return items?.count ?? 1
        itemArray = [RealmItem]()
        syncResultsRealmItemAndItemArray()
        return itemArray.count
        #else
        // #TODO Implement categories for target PList
        return 0
        #endif
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        
        #if CoreData
        let item = itemArray[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = item.done ? .checkmark : .none
        #elseif Realm
        itemArray = [RealmItem]()
        syncResultsRealmItemAndItemArray()
        let item = itemArray[indexPath.row]
        //if let safeItem = items?[indexPath.row] {
        //    cell.textLabel?.text = safeItem.title
        //    cell.accessoryType   = safeItem.done ? .checkmark : .none
        //} else {
        //    cell.textLabel?.text = "No Items Added Yet"
        //}
        
        if let tempItemParentCategoryFirstName = item.parentCategory.first?.name {
            cell.textLabel?.text = item.title + ": " + tempItemParentCategoryFirstName
        }
        cell.textLabel?.text = item.title
        cell.accessoryType   = item.done ? .checkmark : .none
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
        
        //if let safeRealmResultsItem = items?[indexPath.row] {
        //    do {
        //        try realm.write {
        //            safeRealmResultsItem.done = !safeRealmResultsItem.done
        //        }
        //    } catch {
        //        print("Error writing and adding Item to Realm: \(error)")
        //    }
        //}
        syncResultsRealmItemAndItemArray()
        do {
            try realm.write {
                itemArray[indexPath.row].done = !itemArray[indexPath.row].done
                
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
        ///saveItems()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Add New Items
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
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
                print("TodoListViewController::" + #function + " => selectedCategory is " + currentCategory.name)
                do {
                    try self.realm.write {
                        let newItem = RealmItem()
                        newItem.title = textField.text!
                        newItem.dateCreated = Date()
                        currentCategory.items.append(newItem)
                        //self.saveItems(item: newItem)
                    }
                } catch {
                    print("Error writing and adding Item to Realm: \(error)")
                }
            } else {
                print("TodoListViewController::" + #function + " => self.selectedCategory is null, so cannot realm.write the newItem!")
            }
            
            self.syncResultsRealmItemAndItemArray()
            #else
            let newItem = ItemPList()
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
    func saveItems(item: RealmItem) {
        syncResultsRealmItemAndItemArray()
        do {
            try realm.write {
                realm.add(item)
            }
        } catch {
            print("Error writing and adding Item to Realm: \(error)")
        }
        tableView.reloadData()
    }
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
            let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHED %@", selectedCategory!.name!)
            
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
    func loadItems() {
        // Compiler Error: Cannot assign value of type 'Results<RealmItem>?' to type '[RealmItem]'
        //itemArray = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
        
        if let safeSelectedCategory = selectedCategory {
            print(#function + " => selectedCategory is " + safeSelectedCategory.name)
        } else {
            print("####### " + #function + " => selectedCategory is nil!")
        }
        
        if let resultsRealmItem = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true) {
            itemArray = resultsRealmItem.reversed().reversed()
        } else {
            print("####### " + #function + " => selectedCategory is nil, therefore calling syncResultsRealmItemAndItemArray()")
            syncResultsRealmItemAndItemArray()
        }
        
        tableView.reloadData()
    }
    #else
    func loadItems() {
        if let safeData = try? Data(contentsOf: dataFilePath!) {
            let decoder = PropertyListDecoder()
            do {
                itemArray = try decoder.decode([ItemPList].self, from: safeData)
            } catch {
                print("Error decoding item array: \(error)")
            }
        }
        tableView.reloadData()
    }
    #endif
    
    #if Realm
    func syncResultsRealmItemAndItemArray() {
        let resultsRealmItem = realm.objects(RealmItem.self)
        itemArray = resultsRealmItem.reversed().reversed()
    }
    #endif
}

//MARK: - Search Bar Methods
extension TodoListViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        #if CoreData
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
        // Next, we're going to give an array with a single item back to request.sortDescriptors
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        loadItems(with: request, and: predicate)
        #elseif Realm
        //items = items?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "title", ascending: true)
        let resultsRealmItem = realm.objects(RealmItem.self)
        let filteredSortedResultsRealmItem = resultsRealmItem.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "dateCreated", ascending: false)
        itemArray = filteredSortedResultsRealmItem.reversed().reversed()
        tableView.reloadData()
        #else
        #endif
        
        print(#function + " => \"" + searchBar.text! + "\"")
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
}
