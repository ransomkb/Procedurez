//
//  MetaTableViewController.swift
//  Procedurez
//
//  Created by Ransom Barber on 11/9/15.
//  Copyright © 2015 Ransom Barber. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

class MetaTableViewController: UITableViewController {
    
    var alertMessage: String?
    
    // Array for the table view
    var proceduresMeta: [ParseProcedure]?
    var procedurezArray: [CKRecord]?
    
    @IBOutlet weak var tableViewCell: UITableViewCell!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var firstPlacement = self.tableView.center
        firstPlacement.y += 200
        firstPlacement.x = 300
        self.activityIndicator.center = firstPlacement
        
        //proceduresMeta = [ParseProcedure]()
        self.procedurezArray = [CKRecord]()
        
        // Place the Add button (to skip Parse.com and add JSON formatted Procedure string directly).
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(MetaTableViewController.segueToImport))
        
        self.fillTableRows()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
    }
    
    // Skip Parse.com and add JSON formatted Procedure string directly via ImportStringViewController
    @IBAction func segueToImport() {
        let navigationController = splitViewController!.viewControllers[splitViewController!.viewControllers.count-1] as! UINavigationController
        let controller = self.storyboard?.instantiateViewControllerWithIdentifier("ImportStringViewController") as! ImportStringViewController
        NetLoader.sharedInstance().isSegue = false
        navigationController.pushViewController(controller, animated: true)
    }
    
    func fillTableRows() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            
            self.activityIndicator.startAnimating()
            
            let reference = CKReference(recordID: CKRecordID(recordName: NetLoader.CloudDictValues.Grandpa), action: .None)
            
            NetLoader.sharedInstance().queryChildrenRecords(reference, completionHandler: { (success, error) in
                dispatch_async(dispatch_get_main_queue(), {
                    
                    self.activityIndicator.stopAnimating()
                    if success {
                        print("Finished getting array of record items.")
                        //self.procedurezArray.removeAll(keepCapacity: true)
                        self.procedurezArray = NetLoader.sharedInstance().recordArray
                        self.tableView.reloadData()
                    } else if error != nil {
                        self.alertMessage = "Error: Search failed: \(error!.localizedDescription)"
                        self.alertUser()
                    } else {
                        print("Could find no Steps with Grandpa as parent")
                    }
                })
            })
        }
    }
    

    // MARK: - Table view functions
    
    // Return 1 as there will only ever be 1 section.
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // Return the count of the metaArray property.
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //return proceduresMeta!.count
        return self.procedurezArray!.count
    }
    
    // Return a cell configured to the meta data of a Procedure.
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Dequeue a cell and get the appropriate meta data from the array.
        let cell = tableView.dequeueReusableCellWithIdentifier("MetaCell", forIndexPath: indexPath) as UITableViewCell
        let step = self.procedurezArray![indexPath.row]
        let title = step["title"]!
        cell.textLabel?.text = title as? String
        cell.detailTextLabel?.text = step["details"] as? String
        return cell
    }
    
    // Segue to ImportStringViewController if a cell is selected.
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        dispatch_async(dispatch_get_main_queue(), {
            
            if let navigationController = self.splitViewController!.viewControllers[self.splitViewController!.viewControllers.count-1] as? UINavigationController {
                let controller = self.storyboard?.instantiateViewControllerWithIdentifier("ImportCloudKitStep") as! ImportCloudKitStep
                
                let topStep = self.procedurezArray![indexPath.row]
                NetLoader.sharedInstance().stepRecord = topStep
                controller.ckStep = topStep
                
                NetLoader.sharedInstance().isSegue = true
                navigationController.pushViewController(controller, animated: true)
            }
        })
    }
    
    // IMPORTANT: Hide this when putting on storeß
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        // Delete table view procedure from managedObjectContext.
        if editingStyle == .Delete {
            let deleteMe = self.procedurezArray![indexPath.row]
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                
                NetLoader.sharedInstance().publicDB.deleteRecordWithID(deleteMe.recordID, completionHandler: { (deletedRecordID, error) in
                    if error == nil {
                        print("Deleted the record")
                        
                        self.fillTableRows()
                    } else {
                        print("Failed to delete record: \(error?.localizedDescription)")
                    }
                })
            }
        }
    }

    
    // Use UIAlertController to keep user informed.
    func alertUser() {
        
        // Create an instance of alert controller.
        let alertController = UIAlertController(title: "Issue Occurred", message: self.alertMessage, preferredStyle: .Alert)
        
        
        // Set up an OK action button on alert.
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        // Add OK action button to alert.
        alertController.addAction(okAction)
        
        // Dispatch alert to main queue.
        dispatch_async(dispatch_get_main_queue(), {
            
            // Present alert controller.
            self.presentViewController(alertController, animated: true, completion: nil)
        })
    }
    
}
