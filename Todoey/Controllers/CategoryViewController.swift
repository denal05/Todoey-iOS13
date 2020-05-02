//
//  CategoryViewController.swift
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
#endif

// #TODO Refactor class from CategoryViewController into CategoriesViewController
// Main.storyboard > TableView > ID > Custom Class: CategoriesViewController
class CategoryViewController: UITableViewController {

    #if CoreData
    // Surround class name Category with backticks to avoid confusion with Opaque Pointer called Category
    var categoryArray = [`Category`]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    #elseif Realm
    let realm = try! Realm()
    var categoryArray = [RealmCategory]()
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
        loadCategories()
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
        // #TODO Implement categories for target Realm
        return 1
        #else
        // #TODO Implement categories for target PList
        return 0
        #endif
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)

        #if CoreData
        let category = categoryArray[indexPath.row]
        cell.textLabel?.text = category.name
        #elseif Realm
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
    #elseif Realm
    func save(category: RealmCategory) {
        do {
            try realm.write {
                realm.add(category)
            }
        } catch {
            print("Error writing and adding Category to Realm: \(error)")
        }
        tableView.reloadData()
    }
    #else
    #endif
    
    #if CoreData
    func loadCategories(with request: NSFetchRequest<`Category`> = `Category`.fetchRequest()) {
        do {
            categoryArray = try context.fetch(request)
        } catch {
            print("Error fetching from context and Reading category from DB: \(error)")
        }
        
        tableView.reloadData()
    }
    #elseif Realm
    func loadCategories() {
        // #TODO Implement for target Realm
    }
    #else
    #endif
    
    // MARK: - Table view delegate methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! TodoListViewController
        if let safeIndexPath = tableView.indexPathForSelectedRow {
            #if CoreData
            destinationVC.selectedCategory = categoryArray[safeIndexPath.row]
            #elseif Realm
            #else
            #endif
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        #if CoreData
        performSegue(withIdentifier: "goToItems", sender: self)
        #elseif Realm
        #else
        #endif
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Add New Categories
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Todoey Category", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Category", style: .default) { (action) in
            #if CoreData
            let newCategory = `Category`(context: self.context)
            newCategory.name = textField.text!
            self.categoryArray.append(newCategory)
            self.saveCategories()
            #elseif Realm
            let newCategory = RealmCategory()
            newCategory.name = textField.text!
            self.categoryArray.append(newCategory)
            self.save(category: newCategory)
            #else
            #endif
            
        }
        
        alert.addTextField { (tempAlertTextField) in
            tempAlertTextField.placeholder = "Write your new category here"
            textField = tempAlertTextField
        }
        
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
}
