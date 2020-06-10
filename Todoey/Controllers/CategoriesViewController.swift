//
//  CategoriesViewController.swift
//  Todoey
//
//  Originally created by Angela Yu on 01/12/2017.
//  Adapted by Denis Aleksandrov on 2020-05-01.
//  Copyright © 2020 App Brewery. All rights reserved.
//

import UIKit
#if CoreData
import CoreData
#elseif Realm
import RealmSwift
import ChameleonFramework
#endif

class CategoriesViewController: SwipeTableViewController {

    #if CoreData
    // Surround class name Category with backticks to avoid confusion with Opaque Pointer called Category
    var categoryArray = [`Category`]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    #elseif Realm
    let realm = try! Realm()
    let results = try! Realm().objects(RealmCategory.self).sorted(byKeyPath: "name")
    var notificationToken: NotificationToken?
    
    // Compiler Error: Expected member name or constructor call after type name
    //var categories = Results<RealmCategory>!
    //var categories = Results<RealmCategory>?
    
    #else
    #endif
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        #if CoreData
        loadCategories()
        #elseif Realm
        tableView.separatorStyle = .none
        observeRealmResultsAndUpdateTableView()
        #else
        //loadCategories()
        #endif
    }

    // MARK: - Table view data source methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        #if CoreData
        return categoryArray.count
        #elseif Realm
        return results.count
        #else
        // #TODO Implement categories for target PList
        return 0
        #endif
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        #if CoreData
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        let category = categoryArray[indexPath.row]
        cell.textLabel?.text = category.name
        #elseif Realm
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let category = results[indexPath.row]
        cell.textLabel?.text = category.name ?? "No Categories Added Yet"
        cell.backgroundColor = UIColor(hexString: results[indexPath.row].colour ?? "1D9BF6")
        cell.textLabel?.textColor = ContrastColorOf(cell.backgroundColor!, returnFlat: true)
        #else
        #endif

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Data manipulation methods
    #if CoreData
    func saveCategories() {
        do {
            try context.save()
        } catch {
            print("Error saving context and Creating category in DB: \(error)")
        }
        tableView.reloadData()
    }
    
    func loadCategories(with request: NSFetchRequest<`Category`> = `Category`.fetchRequest()) {
        do {
            categoryArray = try context.fetch(request)
        } catch {
            print("Error fetching from context and Reading category from DB: \(error)")
        }
        
        tableView.reloadData()
    }
    #elseif Realm
    #else
    #endif
    
    #if CoreData
    #elseif Realm
    override func updateModel(at indexPath: IndexPath) {
        let categoryForDeletion = self.results[indexPath.row]
        self.realm.beginWrite()
        self.realm.delete(categoryForDeletion)
        try! self.realm.commitWrite()
        observeRealmResultsAndUpdateTableView()
    }
    #else
    #endif
    
    // MARK: - Table view delegate methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! ItemsViewController
        if let safeIndexPath = tableView.indexPathForSelectedRow {
            #if CoreData
            destinationVC.selectedCategory = categoryArray[safeIndexPath.row]
            #elseif Realm
            let category = results[safeIndexPath.row]
            destinationVC.selectedCategory = category
            #else
            #endif
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        #if CoreData
        performSegue(withIdentifier: "goToItems", sender: self)
        #elseif Realm
        performSegue(withIdentifier: "goToItems", sender: self)
        #else
        #endif
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Add New Categories
    
    @IBAction @objc func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Todoey Category", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Category", style: .default) { (action) in
            #if CoreData
            let newCategory = `Category`(context: self.context)
            newCategory.name = textField.text!
            self.categoryArray.append(newCategory)
            self.saveCategories()
            #elseif Realm
            // Since category is a Results data type, which is an auto-updating
            // container type in Realm, at this point we don't need to append
            // the newCategory to an array like we did when using CoreData.
            
            do {
                let newCategory = RealmCategory()
                newCategory.name = textField.text!
                newCategory.colour = UIColor.randomFlat().hexValue()

                self.realm.beginWrite()
                // https://stackoverflow.com/questions/37355078/what-is-the-difference-between-add-and-create
                //self.realm.create(RealmCategory.self, value: [textField.text!, Date(), ])
                self.realm.add(newCategory)
                try! self.realm.commitWrite()
                
                // Updating the tableView by inserting, deleting or reloading rows fixes "NSInternalInconsistencyException, reason: Invalid update: invalid number of rows in section 0."
                self.observeRealmResultsAndUpdateTableView()
            } catch {
                print("Error writing and adding Category to Realm: \(error)")
            }
            #else
            #endif
            
            self.tableView.reloadData()
        }
        
        alert.addTextField { (tempAlertTextField) in
            tempAlertTextField.placeholder = "Write your new category here"
            textField = tempAlertTextField
        }
        
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
        tableView.reloadData()
    }
    
    #if Realm
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
                self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                self.tableView.endUpdates()
            case .error(let err):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(err)")
            }
        }
    }
    #endif
}
