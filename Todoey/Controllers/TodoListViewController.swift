//
//  ViewController.swift
//  Todoey
//
//  Originally created by Philipp Muellauer on 02/12/2019.
//  Adapted by Denis Aleksandrov on 2020-04-25.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
import CoreData

class TodoListViewController: UITableViewController {
    #if CoreData
    var itemArray = [Item]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    #else
    var itemArray = [ItemPList]()
    #endif
    //var userDefaults = UserDefaults.standard
    let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Items.plist")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if CoreData
            print("TodoListViewController::" + #function + " => CoreData Target")
        #else
            print("TodoListViewController::" + #function + " => PList Target")
        #endif
        
        print("TodoListViewController::" + #function + " => ")
        print(dataFilePath)
        
//        let newItem1 = ItemPList()
//        newItem1.title = "First"
//        itemArray.append(newItem1)
//
//        let newItem2 = ItemPList()
//        newItem2.title = "Second"
//        itemArray.append(newItem2)
//
//        let newItem3 = ItemPList()
//        newItem3.title = "Third"
//        itemArray.append(newItem3)
        
        loadItems()
    }
    
    //MARK - Tableview Datasource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoItemCell", for: indexPath)
        
        let item = itemArray[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = item.done ? .checkmark : .none
        
        return cell
    }
    
    //MARK - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        #if CoreData
        //itemArray[indexPath.row].setValue("Completed!", forKey: "title")
        #else
        #endif
        itemArray[indexPath.row].done = !itemArray[indexPath.row].done
        saveItems()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK - Add New Items
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Todoey Action", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            #if CoreData
            let newItem = Item(context: self.context)
            #else
            let newItem = ItemPList()
            #endif
            newItem.title = textField.text!
            newItem.done = false
            self.itemArray.append(newItem)
            self.saveItems()
        }
        
        alert.addTextField { (tempAlertTextField) in
            tempAlertTextField.placeholder = "Write your new item here"
            textField = tempAlertTextField
        }
        
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    func saveItems() {
        #if CoreData
        do {
            try context.save()
        } catch {
            print("Error saving context and Creating item in DB: \(error)")
        }
        #else
        let encoder = PropertyListEncoder()
        do {
            let data = try encoder.encode(itemArray)
            try data.write(to: dataFilePath!)
        } catch {
            print("Error encoding item array: \(error)")
        }
        #endif
        tableView.reloadData()
    }
    
    func loadItems() {
        #if CoreData
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        do {
            itemArray = try context.fetch(request)
        } catch {
            print("Error fetching from context and Reading item from DB: \(error)")
        }
        #else
        if let safeData = try? Data(contentsOf: dataFilePath!) {
            let decoder = PropertyListDecoder()
            do {
                itemArray = try decoder.decode([ItemPList].self, from: safeData)
            } catch {
                print("Error decoding item array: \(error)")
            }
        }
        #endif
    }
    
}

