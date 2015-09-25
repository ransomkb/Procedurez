//
//  DetailViewController.swift
//  TableViewTester
//
//  Created by Ransom Barber on 9/20/15.
//  Copyright (c) 2015 Ransom Barber. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleTextField: UITextField!
    
    @IBOutlet weak var detailsTextView: UITextView!
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    
    var managedObjectContext: NSManagedObjectContext? = nil
    
    let detailCellIdentifier = "DetailCell"
    
    var isDone = true
    var isStep = true
    var isMovingStep = false
    var entityName = "Step"
    
    var sectionSortDescriptorKey = "done"
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
        if let _: AnyObject = detailItem {
            print("Do have a detail item")
            
            if let det = detailItem?.details {
                print("Step has details")
                
                if let detailsTV = detailsTextView {
                    print("Setting details text view value")
                    detailsTV.text = det
                }
                
                if let detailsL = detailsLabel {
                    print("Setting details label value")
                    detailsL.text = det
                }
            }
            
            if let proTitle = self.detailItem?.title {
                print("Step has a title")
                
                if let titTF = titleTextField {
                    print("Setting title text field value")
                    
                    titTF.text = proTitle
                }
                
                if let titL = titleLabel {
                    print("Setting title label value")
                    
                    titL.text = proTitle
                }
            }
            
            //IMPORTANT: EXAMPLE OF KVC: detail.valueForKey("timeStamp")!.description
        }
        
        print("Now detailItem has \(self.detailItem?.children.count) children")
    }
    
   
    @IBAction func saveData(sender: AnyObject) {
        print("Saving the Data")
        let context = self.fetchedResultsController.managedObjectContext
        
        print("Do have a procedure; saving title")
        self.detailItem!.title = self.titleTextField.text!
        self.detailItem!.details = self.detailsTextView.text!
        
        titleLabel.text = self.detailItem?.title
        detailsLabel.text = self.detailItem?.details
        
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
        
        self.tableView.editing = false
        updatePositions()
        hideUI()
    }
    
    @IBAction func editData(sender: AnyObject) {
        self.tableView.editing = true
        hideUI()
    }
    
    
    // MARK - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("View did load")
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        
        self.titleTextField.delegate = self
        self.detailsTextView.delegate = self
        
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        print("View will appear")
        // Subscribe to keyboard notifications to bring up keyboard when typing in textField begins.
        //self.subscribeToKeyboardNotifications()
        if (self.titleTextField.text != "Tap to Edit Name") && !saveButton.hidden {
            hideUI()
        }
        
        updatePositions()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Unsubscribe from keyboard notifications when segueing.
        //self.unsubscribeFromKeyboardNotifications()
    }
    
    
    // MARK: - Misc
    
    func insertNewObject(sender: AnyObject) {
        print("Inserting new Step object")
        let context = self.fetchedResultsController.managedObjectContext
        let entity = self.fetchedResultsController.fetchRequest.entity!
        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context)
        
        let editName = "Tap to Edit Name"
        //let editDetails = "Add a short description"
        
        // If appropriate, configure the new managed object.
        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
        // IMPORTANT: this may be wrong. Check
        newManagedObject.setValue(editName, forKey: "title")
        //newManagedObject.setValue(editDetails, forKeyPath: "details")
        newManagedObject.setValue(self.detailItem, forKey: "parent")
        newManagedObject.setValue(!self.isDone, forKeyPath: self.sortDescriptorKey)
        
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
        titleTextField.hidden = !titleTextField.hidden
        detailsTextView.hidden = !detailsTextView.hidden
        editButton.hidden = !editButton.hidden
        titleLabel.hidden = !titleLabel.hidden
        detailsLabel.hidden = !detailsLabel.hidden
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

    // MARK: - Segues
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        print("Preparing for Segue to Detail")
//        if segue.identifier == "ShowChildren" {
//            print("Have a segue identifier called ShowChildren")
//            if let indexPath = self.tableView.indexPathForSelectedRow {
//                let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Step
//                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
//                controller.detailItem = object
//                controller.managedObjectContext = self.managedObjectContext
//                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
//                controller.navigationItem.leftItemsSupplementBackButton = true
//                
//                print("Destination view controller set up")
//            }
//        } else {
//            print("ShowChildren segue identifier was not found")
//        }
//    }

    
    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        print("Number of Rows in Section: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    // IMPORTANT: fix this
//    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//        //tableView.rowHeight = UITableViewAutomaticDimension
//        print("\(tableView.rowHeight)")
//        return 44.0 //tableView.rowHeight
//    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        print("Index path: \(indexPath)")
        print("Row: \(indexPath.row)")
        
        let cell = tableView.dequeueReusableCellWithIdentifier(detailCellIdentifier, forIndexPath: indexPath) //as? UITableViewCell
        
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Step
        print("This cell object has position: \(object.position)")
        print("This cell object has title: \(object.title)")
        
        cell.textLabel?.text = object.valueForKey("title")!.description
        cell.detailTextLabel?.text = object.valueForKey("details")?.description
        
        return cell
        //return configureCell(indexPath)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
            
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
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        print("Moving cell")
        
        isMovingStep = true
        
        if var steps = self.fetchedResultsController.fetchedObjects {
            let step = steps[sourceIndexPath.row] as! Step
            steps.removeAtIndex(sourceIndexPath.row)
            steps.insert(step, atIndex: destinationIndexPath.row)
            
            //updatePositions()
            var iter : Int32 = 0
            for step in steps as! [Step] {
                print("Step array position: \(iter)")
                print("Step title: \(step.title)")
                step.position = iter
                ++iter
            }
            
            var error: NSError? = nil
            do {
                try self.managedObjectContext!.save()
            } catch let error1 as NSError {
                error = error1
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                print("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
        
        isMovingStep = false
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            tableView.reloadRowsAtIndexPaths(tableView.indexPathsForVisibleRows!, withRowAnimation: UITableViewRowAnimation.Fade)
        })

        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Step
            let controller = self.storyboard?.instantiateViewControllerWithIdentifier("DetailViewController") as! DetailViewController
            
            //let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
            controller.detailItem = object
            controller.managedObjectContext = self.managedObjectContext
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
            controller.navigationItem.leftItemsSupplementBackButton = true
            
            print("Destination view controller set up")
            
            self.navigationController?.pushViewController(controller, animated: true)
        }

        
    }
    
    func configureCell(indexPath: NSIndexPath) -> TableViewCell {
        
        // Dequeue custom cell as TableViewCell.
        if let cell: TableViewCell = tableView.dequeueReusableCellWithIdentifier(detailCellIdentifier, forIndexPath: indexPath) as? TableViewCell {
            print("Cell is a TableViewCell")
            
            
            let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
            let text = object.valueForKey("title")!.description
            if let label = cell.nameLabel {
                
                print("Have a namelabel for cell")
                label.text = text
            } else {
                print("no namelabel in cell")
                cell.textLabel?.text = text
            }
            
            return cell
        }
        let oldCell = TableViewCell()
        return oldCell
    }
    
    func updatePositions() {
        print("Updating positions")
        if let steps = self.fetchedResultsController.fetchedObjects {
            
            isMovingStep = true
            
            //var idx : Int32 = Int32(steps.count)
            var iter : Int32 = 0
            for step in steps as! [Step] {
                print("Step array position: \(iter)")
                print("Step title: \(step.title)")
                step.position = iter
                ++iter
            }
            
            isMovingStep = false
        }
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
        let sectionSortDescriptor = NSSortDescriptor(key: self.sectionSortDescriptorKey, ascending: true)
        let sortDescriptor = NSSortDescriptor(key: self.sortDescriptorKey, ascending: true)
        //_ = [sortDescriptor]
        let predicate = NSPredicate(format: "parent == %@", self.detailItem!)
        
        fetchRequest.sortDescriptors = [sectionSortDescriptor, sortDescriptor]
        fetchRequest.predicate = predicate
        
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
    
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        if isMovingStep {
            return
        }
        
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        if isMovingStep {
            return
        }
        
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        if isMovingStep {
            return
        }
        
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            _ = configureCell(indexPath!)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
        
    }
    
    //    func controller(controller: NSFetchedResultsController, didChangeObject anObject: NSManagedObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    //            }
    
    // IMPORTANT: not using this because wish to try refreshing for background color.
    //    func controllerDidChangeContent(controller: NSFetchedResultsController) {
    //        self.tableView.endUpdates()
    //    }
    
    
    // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        if isMovingStep {
            return
        }
        
        // In the simplest, most efficient, case, reload the table view.
        // IMPORTANT: added the end updates as no changes immediately when adding otherwise.
        self.tableView.endUpdates()
        self.tableView.reloadData()
    }
    
    // MARK: - TextField related
    
    // Clear the default text when text field is selected.
    func textFieldDidBeginEditing(textField: UITextField) {
        if (self.titleTextField.text == "Tap to Edit Name") {
            self.titleTextField.text = ""
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
        
}

