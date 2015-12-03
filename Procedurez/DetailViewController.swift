//
//  DetailViewController.swift
//  TableViewTester
//
//  Created by Ransom Barber on 9/20/15.
//  Copyright (c) 2015 Ransom Barber. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController, NSFetchedResultsControllerDelegate, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var detailsTextView: UITextView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    
    var managedObjectContext: NSManagedObjectContext? = nil
    
    let detailCellIdentifier = "DetailCell"
    
    var alertMessage: String?
    
    // Properties for entity functions
    var isDone = false
    var isStep = true
    var isMovingStep = false
    var entityName = "Step"
    
    var sectionSortDescriptorKey = "sectionIdentifier"
    var sortDescriptorKey = "position"
    
    // Convenience keys
    struct Keys {
        static let Position = "position"
        static let Title = "title"
        static let Details = "details"
    }
    
    // For configuring the Step detailItem
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
            
            // Set the text view and label to the details value.
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
            
            // Set the text field and label to the title value.
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
            
        }
        
        print("Now detailItem has \(self.detailItem?.children.count) children")
    }
    
   // Share the Procedure with others via email or save to Notes.
    @IBAction func shareProcedure(sender: AnyObject) {
        print("Sharing Procedure; Step objectID: \(detailItem?.objectID)")
        
        // Create the JSON data (procedure is actually a Step as detailItem is one).
        if let procedure = detailItem {
            
            // Create a JSON formatted string.
            let json = procedure.getJSONDictionary()
            print(json)
            
            // Prepare for displaying the JSON in an array for the Activity View Controller.
            let activityItems = [json]
            
            // Present UIActivityViewController on main queue.
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                // Set up Activity View Controller
                let nextController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                nextController.popoverPresentationController?.sourceView = self.view
                self.presentViewController(nextController, animated: true, completion: nil)
            })
            
        } else {
            print("Procedure for detailItem is nil")
        }
    }
    
    // Save the data in text field and text view to CoreData.
    @IBAction func saveData(sender: AnyObject) {
        print("Saving the Data")
        
        // Get the context.
        let context = self.fetchedResultsController.managedObjectContext
        
        // Assign text field and view values to the title and detail properties of the Step entity of the detail item.
        print("Do have a procedure; saving title")
        print(self.titleTextField.text!)
        self.detailItem!.title = self.titleTextField.text!
        self.detailItem!.details = self.detailsTextView.text!
        print(self.detailItem!.title)
        
        // Prepare the labels.
        titleLabel.text = self.detailItem?.title
        detailsLabel.text = self.detailItem?.details
        
        // Adjust positions in fetched results controller after cell is moved/deleted.
        updatePositions()
        
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
        
        // Allow changes to fetched results controller, finally.
        self.tableView.editing = false
        
        // Make sure the keyboard is gone.
        titleTextField.resignFirstResponder()
        detailsTextView.resignFirstResponder()
        
        //Hide text field and text view, etc.
        hideUI()
    }
    
    // Unhide text field and text view, etc.
    @IBAction func editData(sender: AnyObject) {
        // Prevent premature changes to fetched results controller.
        self.tableView.editing = true
        hideUI()
    }
    
    
    
    // MARK - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Detail View did load: start")
        
        // Add a button for creating substeps / children.
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        
        // Add a share button if this is the first Step.
        let rightBarButtonItems: [UIBarButtonItem]!
        if (detailItem?.parent == nil) {
            rightBarButtonItems = [addButton, shareButton]
        } else {
            rightBarButtonItems = [addButton]
        }
        
        self.navigationItem.rightBarButtonItems = rightBarButtonItems
        
        // Make self delegate for various objects.
        self.titleTextField.delegate = self
        self.detailsTextView.delegate = self
        
        // Capitalize first letters of title text field.
        // (Works in simulator only if software keyboard is toggled.)
        self.titleTextField.autocapitalizationType = .Words
        self.tableView.separatorStyle = .None
        
        self.configureView()
        print("Detail View did load: end")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("Detail View will appear: start")
        
        // Ensure correct UI is visible for a new Step.
        if (self.titleTextField.text != "Tap to Edit Name") && !saveButton.hidden {
            hideUI()
        }
        
        print("Detail View will appear: end")
    }
    
    
    
    // MARK: - Misc
    
    // Insert a new Step entity object into CoreData.
    func insertNewObject(sender: AnyObject) {
        print("Inserting new Step object")
        
        // Prepare to insert Step entity.
        let context = self.fetchedResultsController.managedObjectContext
        let entity = self.fetchedResultsController.fetchRequest.entity!
        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context)
        
        let editName = "Tap to Edit Name"
        
        //print("isDone: \(isDone)")
        
        // Set necessary Step properties.
        newManagedObject.setValue(editName, forKey: "title")
        newManagedObject.setValue(self.detailItem, forKey: "parent")
        newManagedObject.setValue(isDone, forKey: "done")
        newManagedObject.setValue("Do", forKey: "sectionIdentifier")
        
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
    
    // Hide and Unhide the User Interface labels, text fields, text views, buttons, etc.
    func hideUI() {
        print("Hiding the UI")
        saveButton.hidden = !saveButton.hidden
        titleTextField.hidden = !titleTextField.hidden
        detailsTextView.hidden = !detailsTextView.hidden
        editButton.hidden = !editButton.hidden
        titleLabel.hidden = !titleLabel.hidden
        detailsLabel.hidden = !detailsLabel.hidden
    }
    
    
    // MARK: - Table View
    
    // Return number of sections.
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    // Return number of rows in section.
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        print("Number of Rows in Section: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    // Adjust the section header to Do or Done.
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            print("Current Section: \(currentSection.name)")
            return currentSection.name
        }
        
        return nil
    }
    
    // Return a cell configured to the properties of a child of the detailItem/Step.
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        print("Index path: \(indexPath)")
        print("Row: \(indexPath.row)")
        
        // Get the child.
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Step
        
        print("This cell object has position: \(object.position)")
        print("This cell object has title: \(object.title)")
        print("This cell object has done value: \(object.done)")
        print("This cell object has sectionIdentifier: \(object.sectionIdentifier)")
        print("This cell object has children: \(object.children)")
        
        // Dequeue a cell.
        let cell = tableView.dequeueReusableCellWithIdentifier(detailCellIdentifier, forIndexPath: indexPath)
        
        // Set the background to the correct image.
        cell.backgroundView = UIImageView(image: UIImage(named: setBackgroundImage(object, indexPathRow:indexPath.row)))
        
        // Remove the selection highlighting.
        cell.selectionStyle = .None
        
        // Make the text more readable on the colorful images.
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.detailTextLabel?.textColor = UIColor.whiteColor()
        
        // Set the text values of the cell.
        cell.textLabel?.text = object.valueForKey("title")!.description
        cell.detailTextLabel?.text = object.valueForKey("details")?.description
        
        // Make the cell swipable from left to right to let it be moved to the Done section.
        let swipeRight = UISwipeGestureRecognizer(target: self, action: "handleRightSwipe:")
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        cell.addGestureRecognizer(swipeRight)
        
        // Hide the discolsure symbol if there are no grandchildren / substeps in this substep.
        if object.children.isEmpty {
            print("No children")
            
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    // Make table editable, allowing cells to be moved.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Handle .Delete type editing.
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        if editingStyle == .Delete {
            
            // Get the context and delete the object in the cell.
            let context = self.fetchedResultsController.managedObjectContext
            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
            
            // Adjust positions in fetched results controller after cell is moved/deleted.
            updatePositions()
            
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
    }
    
    // Handle moving the row.
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        print("Moving cell")
        
        // Ensure the fetched results controller and table view do not make changes prematurely.
        isMovingStep = true
        
        if var steps = self.fetchedResultsController.fetchedObjects {
            
            // Get the step to be moved, remove it, and reinsert it in the fetched results controller.
            let step = steps[sourceIndexPath.row] as! Step
            steps.removeAtIndex(sourceIndexPath.row)
            steps.insert(step, atIndex: destinationIndexPath.row)
            
            // Update the order/positions of the steps.
            var iter : Int32 = 0
            for step in steps as! [Step] {
                print("Step array position: \(iter)")
                print("Step title: \(step.title)")
                step.position = iter
                ++iter
            }
            
            // Save the context.
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
        
        // Remove the premature preventative.
        isMovingStep = false
        
        // Update the table vew rows.
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            tableView.reloadRowsAtIndexPaths(tableView.indexPathsForVisibleRows!, withRowAnimation: UITableViewRowAnimation.Fade)
        })
    }
    
    // Handle row selection.
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            
            // Get the selected child.
            let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Step
            
            // Create a DetailViewController from the storyboard to show the child as a detailItem/Step.
            let controller = self.storyboard?.instantiateViewControllerWithIdentifier("DetailViewController") as! DetailViewController
            
            // Set the properties of the new view controller.
            controller.detailItem = object
            controller.managedObjectContext = self.managedObjectContext
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
            controller.navigationItem.leftItemsSupplementBackButton = true
            
            print("Destination view controller set up")
            
            // Push the new view controller on the navigation stack.
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    // Set the background image of a cell, depending on whether device is iPad or iPhone.
    func setBackgroundImage(step: Step, indexPathRow row: Int) -> String {
        
        // Determine the type of device, then get the image of the appropriate color.
        switch UIDevice.currentDevice().userInterfaceIdiom {
        case .Pad:
            if step.done {
                return "PadGreen"
            } else if row <= 5 {
                let padCellImage = PadCellImage(rawValue: row)
                return (padCellImage?.title())!
            } else {
                return "PadPurple"
            }
        case .Phone:
            if step.done {
                return "PhoneGreen"
            } else if row <= 5{
                let phoneCellImage = PhoneCellImage(rawValue: row)
                return (phoneCellImage?.title())!
            } else {
                return "PhonePurple"
            }
        case .Unspecified:
            return "PhoneBlack"
        default:
            return "PhoneBlack"
        }
    }
    
    // Adjust positions in fetched results controller after cell is moved/deleted.
    func updatePositions() {
        print("Updating positions")
        if let _ = self.managedObjectContext {
            if let steps = self.fetchedResultsController.fetchedObjects {
                
                // Ensure the fetched results controller and table view do not make changes prematurely.
                isMovingStep = true
                
                // Update the order/positions of the steps.
                var iter : Int32 = 0
                for step in steps as! [Step] {
                    print("Step array position: \(iter)")
                    print("Step title: \(step.title)")
                    print("Step done: \(step.done)")
                    step.position = iter
                    ++iter
                }
                
                // Remove the premature preventative.
                isMovingStep = false
            }
        } else {
            return
        }
    }
    
    // Handle right swipe by marking cell as done and moving to Done section.
    func handleRightSwipe(gesture: UISwipeGestureRecognizer) {
    print("Handling swipe")
        
        // Get the point of touch/swipe.
        let point = gesture.locationInView(self.tableView)
        print("Swipe Point: \(point)")
        let indexPath = self.tableView.indexPathForRowAtPoint(point)
        print("Swipe Point index path: \(indexPath)")
        
        // Check the direction of the swipe.
        switch gesture.direction {
        case UISwipeGestureRecognizerDirection.Right:
            // Update the done bool to determine table section.
            let step = self.fetchedResultsController.objectAtIndexPath(indexPath!) as! Step
            step.done = !step.done.boolValue
            step.updateSectionIdentifier()
            break
        default: return
        }
    }
    
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        
        print("Accessing the Details Fetched Results Controller")
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        
        // Deal with fatal error of unexpected nil
        if let _ = self.entityName as String? {
            print("Self.entityName is fine")
        } else {
            print("Self.entityName is NOT fine")
        }
        
        if let _ = self.managedObjectContext {
            print("self.managedObjectContext is fine")
        } else {
            print("self.managedObjectContext is not fine")
            print("Using that of AppDelegate")
            
            self.managedObjectContext = CoreDataStackManager.sharedInstance().managedObjectContext
        }
        
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName(self.entityName, inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sectionSortDescriptor = NSSortDescriptor(key: "sectionIdentifier", ascending: true)
        let sortDescriptor = NSSortDescriptor(key: self.sortDescriptorKey, ascending: true)
        let predicate = NSPredicate(format: "parent == %@", self.detailItem!)
        
        fetchRequest.sortDescriptors = [sectionSortDescriptor, sortDescriptor]
        fetchRequest.predicate = predicate
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: sectionSortDescriptorKey, cacheName: nil)
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
    
    // Prepare for fetched results controller changes.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        // Prevent premature changes.
        if isMovingStep {
            return
        }
        
        self.tableView.beginUpdates()
    }
    
    // Handle section changes to fetched results controller.
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        // Prevent premature changes.
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
    
    // Handle content changes to to fetched results controller.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        // Prevent premature changes.
        if isMovingStep {
            return
        }
        
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update: break
            // Do nothing.
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
        
    }
    
    // Finish changes to table view when changes to fetched results controller are finished.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        // Prevent premature changes.
        if isMovingStep {
            return
        }
        
        // In the simplest, most efficient, case, reload the table view.
        // Added the end updates as no changes immediately when adding otherwise.
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
    
    
    // Drop keyboard when Return is tapped.
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Limit the title to 50 characters.
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        if (range.length + range.location > textField.text?.characters.count )
        {
            return false;
        }
        
        let newLength = (textField.text?.characters.count)! + string.characters.count - range.length
        return newLength <= 50
    }
    
    
    // MARK: - TextView related
    
    // Clear the default text in details text view.
    func textViewDidBeginEditing(textView: UITextView) {
        if (self.detailsTextView.text == "Add a short description") {
            self.detailsTextView.text = ""
        }
    }
    
    // Limit the details text to 140 characters.
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        if (range.length + range.location > textView.text?.characters.count )
        {
            return false;
        }
        
        let newLength = (textView.text?.characters.count)! + text.characters.count - range.length
        return newLength <= 140
    }
    
    
    // Use an UIAlertController to inform user of issue.
    func alertUser() {
        
        // Use the main queue to ensure speed.
        dispatch_async(dispatch_get_main_queue(), {
            
            // Create an instance of UIAlertController.
            let alertController = UIAlertController(title: "Problem", message: self.alertMessage, preferredStyle: .Alert)
            
            // Set the alert message.
            if let message = self.alertMessage {
                alertController.message = message
            }
            
            // Create action button with OK button to dismiss alert.
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action) -> Void in
                
            }
            
            // Add the OK action.
            alertController.addAction(okAction)
            
            // Present the alert controller.
            self.presentViewController(alertController, animated: true, completion: nil)
        })
    }

        
}

