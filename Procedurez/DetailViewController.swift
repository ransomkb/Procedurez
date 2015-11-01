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

    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleTextField: UITextField!
    
    @IBOutlet weak var detailsTextView: UITextView!
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    
    var managedObjectContext: NSManagedObjectContext? = nil
    
    let detailCellIdentifier = "DetailCell"
    
    var alertMessage: String?
    
    var isDone = false
    var isStep = true
    var isMovingStep = false
    var entityName = "Step"
    
    var sectionSortDescriptorKey = "sectionIdentifier"
    var sortDescriptorKey = "position"
    var procedure: Procedure?
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
    
   // Share the Procedure with others via email.
    @IBAction func shareProcedure(sender: AnyObject) {
        print("Sharing Procedure; Step objectID: \(detailItem?.objectID)")
        // Create the JSON data (procedure is actually a Step as detailItem is one).
        if let procedure = detailItem {
            let json = procedure.getJSONDictionary()
            print(json)
            
            let activityItems = [json]
            
            // Present UIActivityViewController on main queue.
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                // Set up Activity View Controller
                let nextController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                nextController.popoverPresentationController?.sourceView = self.view
                //nextController.popoverPresentationController?.sourceRect = sender.frame
                self.presentViewController(nextController, animated: true, completion: nil)
            })
            
            print("json string is a valid json object: \(NSJSONSerialization.isValidJSONObject(json))")
            
            if let data = json.dataUsingEncoding(NSUTF8StringEncoding) {
                print("Data is of type NSData: \(data.isKindOfClass(NSData))")
                
                print("data of json string is a valid json object: \(NSJSONSerialization.isValidJSONObject(data))")
                
                
                let jsonFile = FileSaveHelper(fileName: (detailItem?.title)!, fileExtension: .JSON, subDirectory: "FilesToShare", directory: .DocumentDirectory)
                
                do {
                    //try jsonFile.saveFile(dataForJson: data)
                    try jsonFile.saveFile(string: json)
                } catch {
                    print(error)
                }
                
                print("JSON file to share exists: \(jsonFile.fileExists)")
                
                // IMPORTANT: Practice with importing, too. Change this when all is working.
                NetLoader.sharedInstance().json = json
                //NetLoader.sharedInstance().importJSON()
                
                
                
                // Get the file contents off the hard drive
                if let _ = NSData(contentsOfFile: jsonFile.fullyQualifiedPath) {
                    print("Adding the json file to the activityItems array.")
                    //activityItems.append(data)
                    
                   
                }
            }
        } else {
            print("Procedure for detailItem is nil")
        }
        
    }
    
    @IBAction func saveData(sender: AnyObject) {
        print("Saving the Data")
        let context = self.fetchedResultsController.managedObjectContext
        
        print("Do have a procedure; saving title")
        print(self.titleTextField.text!)
        self.detailItem!.title = self.titleTextField.text!
        self.detailItem!.details = self.detailsTextView.text!
        print(self.detailItem!.title)
        
        titleLabel.text = self.detailItem?.title
        detailsLabel.text = self.detailItem?.details
        
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
        
        self.tableView.editing = false
        //updatePositions()
        hideUI()
    }
    
    @IBAction func editData(sender: AnyObject) {
        self.tableView.editing = true
        hideUI()
    }
    
    
    
    // MARK - View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Detail View did load: start")
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        
        // Add a share button if this is the first Step
        let rightBarButtonItems: [UIBarButtonItem]!
        if (detailItem?.parent == nil) {
            rightBarButtonItems = [addButton, shareButton]
        } else {
            rightBarButtonItems = [addButton]
        }
        
        self.navigationItem.rightBarButtonItems = rightBarButtonItems
        
        self.titleTextField.delegate = self
        self.detailsTextView.delegate = self
        
        self.tableView.separatorStyle = .None
        
        self.configureView()
        print("Detail View did load: end")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        print("Detail View will appear: start")
        // Subscribe to keyboard notifications to bring up keyboard when typing in textField begins.
        //self.subscribeToKeyboardNotifications()
        if (self.titleTextField.text != "Tap to Edit Name") && !saveButton.hidden {
            hideUI()
        }
        
        //updatePositions()
        print("Detail View will appear: end")
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
        print("isDone: \(isDone)")
        //isDone = !isDone
        
        // If appropriate, configure the new managed object.
        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
        // IMPORTANT: this may be wrong. Check
        newManagedObject.setValue(editName, forKey: "title")
        //newManagedObject.setValue(editDetails, forKeyPath: "details")
        newManagedObject.setValue(self.detailItem, forKey: "parent")
        newManagedObject.setValue(isDone, forKey: "done")
        newManagedObject.setValue("Do", forKey: "sectionIdentifier")
        
        let stepName = newManagedObject.valueForKey("title") as! String
        print("Created a step with name: \(stepName)")
        
        // Save the context.
        var error: NSError? = nil
        do {
            try context.save()
            //updatePositions()
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
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            print("Current Section: \(currentSection.name)")
            return currentSection.name
        }
        
        return nil
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
        
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Step
        
        print("This cell object has position: \(object.position)")
        print("This cell object has title: \(object.title)")
        print("This cell object has done value: \(object.done)")
        print("This cell object has sectionIdentifier: \(object.sectionIdentifier)")
        //object.updateSectionIdentifier()
        //print("This cell object now has sectionIdentifier: \(object.sectionIdentifier)")
        
        let cell = tableView.dequeueReusableCellWithIdentifier(detailCellIdentifier, forIndexPath: indexPath) //as? UITableViewCell
        
        let cellBackgroundView = UIImageView(image: UIImage(named: setBackgroundImage(object, indexPathRow:indexPath.row)))
        
        cell.backgroundView = cellBackgroundView
        
        // Remove the selection highlighting.
        cell.selectionStyle = .None
        
        //if !object.done {
            //if indexPath.row == 0 || indexPath.row > 3 {
                cell.textLabel?.textColor = UIColor.whiteColor()
                cell.detailTextLabel?.textColor = UIColor.whiteColor()
            //}
        //}
        
        cell.textLabel?.text = object.valueForKey("title")!.description
        cell.detailTextLabel?.text = object.valueForKey("details")?.description
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: "handleRightSwipe:")
        swipeRight.direction = UISwipeGestureRecognizerDirection.Right
        cell.addGestureRecognizer(swipeRight)
        
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
            
            updatePositions()
            
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
                //updatePositions()
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
    
    func setBackgroundImage(step: Step, indexPathRow row: Int) -> String {
        step.objectID.URIRepresentation().lastPathComponent
        
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
    
    func updatePositions() {
        print("Updating positions")
        if let _ = self.managedObjectContext {
        if let steps = self.fetchedResultsController.fetchedObjects {
            
            isMovingStep = true
            
            //var idx : Int32 = Int32(steps.count)
            var iter : Int32 = 0
            for step in steps as! [Step] {
                print("Step array position: \(iter)")
                print("Step title: \(step.title)")
                print("Step done: \(step.done)")
                step.position = iter
                ++iter
            }
            
            isMovingStep = false
            }
        } else {
            return
        }
    }
    
    func handleRightSwipe(gesture: UISwipeGestureRecognizer) {
    print("Handling swipe")
        
        let point = gesture.locationInView(self.tableView)
        print("Swipe Point: \(point)")
        let indexPath = self.tableView.indexPathForRowAtPoint(point)
        print("Swipe Point index path: \(indexPath)")
        
        switch gesture.direction {
        case UISwipeGestureRecognizerDirection.Right:
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
            //let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
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
        //_ = [sortDescriptor]
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
        case .Update: break
            //_ = configureCell(indexPath!)
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
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        if (range.length + range.location > textField.text?.characters.count )
        {
            return false;
        }
        
        let newLength = (textField.text?.characters.count)! + string.characters.count - range.length
        return newLength <= 50
    }
    
    // MARK: - TextView related
    
    func textViewDidBeginEditing(textView: UITextView) {
        if (self.detailsTextView.text == "Add a short description") {
            self.detailsTextView.text = ""
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        if (range.length + range.location > textView.text?.characters.count )
        {
            return false;
        }
        
        let newLength = (textView.text?.characters.count)! + text.characters.count - range.length
        return newLength <= 140
    }
    
    // MARK: - String related
    // Probably will only be used in Step
    func replaceDoubleQuotes(jsonString: String) -> String {
        return String(jsonString.characters.map{ $0 == "\"" ? "'" : $0 })
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

