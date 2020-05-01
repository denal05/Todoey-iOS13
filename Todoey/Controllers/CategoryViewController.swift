//
//  CategoryViewController.swift
//  Todoey
//
//  Originally created by Angela Yu on 01/12/2017.
//  Adapted by Denis Aleksandrov on 2020-05-01.
//  Copyright © 2020 App Brewery. All rights reserved.
//

import UIKit
import CoreData

// #TODO Refactor class from CategoryViewController into CategoriesViewController
// Main.storyboard > TableView > ID > Custom Class: CategoriesViewController
class CategoryViewController: UITableViewController {

    #if CoreData
    // Surround class name Category with backticks to avoid confusion with Opaque Pointer called Category
    var categoryArray = [`Category`]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    #else
    #endif
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        loadCategories()
    }

    // MARK: - Table view data source methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return categoryArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)

        let category = categoryArray[indexPath.row]
        cell.textLabel?.text = category.name

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
    func saveCategories() {
        #if CoreData
        do {
            try context.save()
        } catch {
            print("Error saving context and Creating category in DB: \(error)")
        }
        #else
        #endif
        tableView.reloadData()
    }
    
    func loadCategories(with request: NSFetchRequest<`Category`> = `Category`.fetchRequest()) {
        #if CoreData
        do {
            categoryArray = try context.fetch(request)
        } catch {
            print("Error fetching from context and Reading category from DB: \(error)")
        }
        #else
        #endif
        
        tableView.reloadData()
    }
    
    // MARK: - Table view delegate methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! TodoListViewController
        if let safeIndexPath = tableView.indexPathForSelectedRow {
            destinationVC.selectedCategory = categoryArray[safeIndexPath.row]
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        #if CoreData
        performSegue(withIdentifier: "goToItems", sender: self)
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
            #else
            #endif
            newCategory.name = textField.text!
            self.categoryArray.append(newCategory)
            self.saveCategories()
        }
        
        alert.addTextField { (tempAlertTextField) in
            tempAlertTextField.placeholder = "Write your new category here"
            textField = tempAlertTextField
        }
        
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
}
