//
//  DetailViewController.swift
//  TableViewTester
//
//  Created by Ransom Barber on 9/20/15.
//  Copyright (c) 2015 Ransom Barber. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController, NSFetchedResultsControllerDelegate, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var detailsTextView: UITextView!
    
    @IBOutlet weak var saveButton: UIButton!
    
    
    @IBOutlet weak var detailDescriptionLabel: UILabel!
    
    var managedObjectContext: NSManagedObjectContext? = nil
    
    var isStep = true
    var entityName = "Step"
    var sortDescriptorKey = "position"
    //var procedure: Procedure?
    //var step: Step?
    
    struct Keys {
        static let Position = "position"
        static let Title = "title"
        static let Details = "details"
    }


    var detailItem: Step? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        print("Configuring detail view")
        // Update the user interface for the detail item.
        
        if let _: AnyObject = self.detailItem {
            print("Do have a detail item")
            
            if let label = self.detailDescriptionLabel {
                label.text = "Step"//detail.valueForKey("timeStamp")!.description
            }
            
            if let name = self.nameTextField {
                print("Setting name text field value")
                if let proTitle = self.detailItem?.title {
                    print("Step has a title")
                    name.text = proTitle
                }
            }
            
            if let details = self.detailsTextView {
                
                print("Setting details text view value")
                if let det = self.detailItem?.details {
                    print("Step has details")
                    details.text = det
                }
            }
        }
        
        print("Now detailItem has \(self.detailItem?.children.count) children")
    }
    
   
    @IBAction func saveData(sender: AnyObject) {
        print("Saving the Data")
        let context = self.fetchedResultsController.managedObjectContext
        
        
        print("Do have a procedure; saving title")
        self.detailItem!.title = self.nameTextField.text!
        self.detailItem!.details = self.detailsTextView.text!
        
        
        // Save the context.
        var error: NSError? = nil
        do {
            try context.save()
        } catch let error1 as NSError {
            error = error1
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            print("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        hideUI()

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        
        self.nameTextField.delegate = self
        self.detailsTextView.delegate = self
        
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Subscribe to keyboard notifications to bring up keyboard when typing in textField begins.
        //self.subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Unsubscribe from keyboard notifications when segueing.
        //self.unsubscribeFromKeyboardNotifications()
    }

    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName(self.entityName, inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: self.sortDescriptorKey, ascending: false)
        _ = [sortDescriptor]
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        var error: NSError? = nil
        do {
            try _fetchedResultsController!.performFetch()
        } catch let error1 as NSError {
            error = error1
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            print("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil
    

    func insertNewObject(sender: AnyObject) {
        print("Inserting new Step object")
        let context = self.fetchedResultsController.managedObjectContext
        let entity = self.fetchedResultsController.fetchRequest.entity!
        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context) 
        
        let editName = "Tap to Edit Name."
        
        
        // If appropriate, configure the new managed object.
        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
        // IMPORTANT: this may be wrong. Check
        newManagedObject.setValue(editName, forKey: "title")
        newManagedObject.setValue(self.detailItem, forKey: "parent")
        
        let stepName = newManagedObject.valueForKey("title") as! String
        print("Created a step with name: \(stepName)")
        
        // Save the context.
        var error: NSError? = nil
        do {
            try context.save()
        } catch let error1 as NSError {
            error = error1
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            print("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        print("Now detailItem has \(self.detailItem?.children.count) children")
    }
    
    func hideUI() {
        print("Hiding the UI")
        saveButton.hidden = !saveButton.hidden
        nameTextField.hidden = !nameTextField.hidden
        detailsTextView.hidden = !detailsTextView.hidden
    }

    // IMPORTANT: maybe don't need
    func configureStep() {
        let context = self.fetchedResultsController.managedObjectContext
        let stepDictionary = [Keys.Position:1, Keys.Title:"Tap to add Step", Keys.Details:"Edit Details"]
        var stepArray = [Step]()
        let step = Step(dictionary: stepDictionary, context: context)
        stepArray.append(step)
        
        // Save the context.
        var error: NSError? = nil
        do {
            try context.save()
        } catch let error1 as NSError {
            error = error1
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            print("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
    }
    
    // MARK: - TextField related
    
    // Clear the default text when text field is selected.
    func textFieldDidBeginEditing(textField: UITextField) {
        if (self.nameTextField.text == "Tap to Edit Name") {
            self.nameTextField.text = ""
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Drop keyboard when Return is tapped.
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - TextView related
    
    func textViewDidBeginEditing(textView: UITextView) {
        if (self.detailsTextView.text == "Add a short description") {
            self.detailsTextView.text == ""
        }
    }
    
    
    
    // Return a float value of the height of the keyboard being used.
//    func getKeyBoardHeight(notificaton: NSNotification) -> CGFloat {
//        let userInfo = notificaton.userInfo
//        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
//        return keyboardSize.CGRectValue().height
//    }
    
    // Slide the whole view up to show the text field when the bottom text field is selected.
//    func keyboardWillShow(notification: NSNotification) {
//        if nameTextField.isFirstResponder() {
//            self.view.frame.origin.y -= getKeyBoardHeight(notification)
//        }
//    }
//    
//    // Slide the whole view down to original position when the bottom text field is selected, and then the return key is tapped.
//    func keyboardWillHide(notification: NSNotification) {
//        if nameTextField.isFirstResponder() {
//            self.view.frame.origin.y += getKeyBoardHeight(notification)
//        }
//    }
    
    // Subscribe to keyboard notifications to show and hide the keyboard appropriately.
//    func subscribeToKeyboardNotifications() {
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
//    }
//    
//    // Unsubscribe from keyboard notifications when segueing to another view controller.
//    func unsubscribeFromKeyboardNotifications() {
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
//    }
    
}

