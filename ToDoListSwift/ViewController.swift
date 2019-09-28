//
//  ViewController.swift
//  ToDoListSwift
//
//  Created by Serkan Buyuk on 27/09/2019.
//  Copyright © 2019 Serkan Buyuk. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var toDoListTableView: UITableView!
    var toDoListItems = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let img = UIImage(named: "getirBG")
        navigationController?.navigationBar.setBackgroundImage(img, for: .default)
        
        toDoListTableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchItems()
    }
    
    /**
     createItem fonksiyonu, bir string alarak bununla bir obje yaratır ve veritabanına ekler.
     
     - parameters:
     - listItem: Yapilacakalar listesine ekleyeceğimiz yeni ürünün String değeri.
     
     */
    
    //MARK: CreateItem
    func createItem(listItem: String){
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "ToDoItem", in: managedContext)!
        
        let item = NSManagedObject(entity: entity, insertInto: managedContext)
        
        item.setValue(listItem, forKey: "item")
        
        do{
            try managedContext.save()
        } catch let error{
            print("Item can't be created: \(error.localizedDescription)")
        }
        
    }
    
    /**
     fetchItems, veritabanındaki kayıtlı verileri bularak tabloya yerleştirir.
     
     */
    
    //MARK: FetchItem
    func fetchItems(){
        toDoListItems.removeAll()
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ToDoItem")
        
        do {
            let fetchResults = try managedContext.fetch(fetchRequest)
            
            for item in fetchResults as! [NSManagedObject]{
                
                toDoListItems.append(item.value(forKey: "item") as! String)
                
            }
            toDoListTableView.reloadData()
            
        } catch let error{
            print(error.localizedDescription)
        }
        
    }
    
    //MARK: RemoveItem
    func removeItem(listItem: String){
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ToDoItem")
        fetchRequest.predicate = NSPredicate(format: "item = %@", listItem)
        
        if let result = try? managedContext.fetch(fetchRequest){
            for item in result{
                managedContext.delete(item)
            }
            
            do {
                try managedContext.save()
                print("Items Saved")
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
    }
    
    //MARK: UpdateItem
    func updateItem(listItem: String){
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ToDoItem")
        fetchRequest.predicate = NSPredicate(format: "item = %@", listItem)
        
        let popup = UIAlertController(title: "Update to-do item", message: "Update to-do item in your list.", preferredStyle: .alert)
        popup.addTextField { (textField) in
            if listItem != "" {
                textField.text = listItem
            } else {
                textField.placeholder = "Item"
            }
        }
        let saveAction = UIAlertAction(title: "Add", style: .default) { (_) in
            
            do {
                let result = try managedContext.fetch(fetchRequest)
                
                let item = result[0]
                item.setValue(popup.textFields?.first?.text ?? "Error", forKey: "item")
            } catch let error {
                print(error.localizedDescription)
            }
            
            self.fetchItems()
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        popup.addAction(saveAction)
        popup.addAction(cancelAction)
        self.present(popup, animated: true, completion: nil)
        
    }
    
    /**
     addTapped fonksiyonu, kullanıcı + butonuna tıkladığında çalışacak aksiyonları başlatır
     
     - parameters:
     - sender: Hangi itemin fonksiyona yollandığını belirtir.
     
     */
    
    //MARK: AddItem
    @IBAction func addTapped(_ sender: UIBarButtonItem) {
        let popup = UIAlertController(title: "Add to-do item", message: "Add to-do item into your list.", preferredStyle: .alert)
        popup.addTextField { (textField) in
            textField.placeholder = "Item"
        }
        let saveAction = UIAlertAction(title: "Add", style: .default) { (_) in
            self.createItem(listItem: popup.textFields?.first?.text ?? "Error")
            self.fetchItems()
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        popup.addAction(saveAction)
        popup.addAction(cancelAction)
        self.present(popup, animated: true, completion: nil)
        
    }
    
}

extension ViewController: UITableViewDataSource, UITableViewDelegate{
    
    //MARK: TableView Functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toDoListItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "listItem") else {
            return UITableViewCell()
        }
        cell.textLabel?.text = toDoListItems[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let remove = UIContextualAction(style: .destructive, title: "Remove") { (action, UIView, (Bool)->Void) in
            self.removeItem(listItem: self.toDoListItems[indexPath.row])
            self.toDoListItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.reloadData()
        }
        
        return UISwipeActionsConfiguration(actions: [remove])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let update = UIContextualAction(style: .normal, title: "Update") { (action, UIView, (Bool) -> Void) in
            self.updateItem(listItem: self.toDoListItems[indexPath.row])
            self.fetchItems()
            tableView.reloadData()
        }
        update.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [update])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let cell = tableView.cellForRow(at: indexPath as IndexPath) {
            if cell.accessoryType == .checkmark {
                cell.accessoryType = .none
            } else {
                cell.accessoryType = .checkmark
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
