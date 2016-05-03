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
        
        // IMPORTANT: see about threading for Core Data on another queue, not Main; this queue is good for fetching from net;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            
            // Used for one time to set up meta; probably do not need it again;
            //NetLoader.sharedInstance().prepareMeta()
            
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
            
            // Used with Parse; changing to cloud kit
            // Ensure getting the meta data of the Procedure from Parse.com.
//            NetLoader.sharedInstance().isMeta = true
//    
//            // Get the meta data of all of the Procedures from Parse.com and place it in an array for the table view.
//            NetLoader.sharedInstance().searchParse { (success, errorString) -> Void in
//                if success {
//                    print("Finished getting array of meta items.")
//                    self.activityIndicator.stopAnimating()
//                    self.proceduresMeta = NetLoader.sharedInstance().metaArray
//                    self.tableView.reloadData()
//                } else {
//                    print(errorString)
//                    
//                    self.activityIndicator.stopAnimating()
//                    self.alertMessage = errorString
//                    self.alertUser()
//                }
//            }
        }
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

        
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
//
//            NetLoader.sharedInstance().stepRecord = NetLoader.sharedInstance().recordArray[indexPath.row]
//            NetLoader.sharedInstance().fetchOneRecordByRecordID(<#T##recordID: CKRecordID##CKRecordID#>, completionHandler: <#T##SuccessCompHandler##SuccessCompHandler##(success: Bool, error: NSError?) -> Void#>)
//                if success {
//                    print("Finished getting a top-level CloudKit Step.")
//                    
//                    dispatch_async(dispatch_get_main_queue(), {
//                        
//                        self.activityIndicator.stopAnimating()
//                        
//                        if let navigationController = self.splitViewController!.viewControllers[self.splitViewController!.viewControllers.count-1] as? UINavigationController {
//                            let controller = self.storyboard?.instantiateViewControllerWithIdentifier("ImportCloudKitStep") as! ImportCloudKitStep
//                            
//                            //let importSteps = NetLoader.sharedInstance().JSONRecord?.valueForKey(NetLoader.ProcedureKeys.Steps) as! String
//
//                            //controller.tempImportText = importSteps
//                                
//                            // Inform ImportStringViewController this is a segue from a cell, not the button.
//                            NetLoader.sharedInstance().isSegue = true
//                            navigationController.pushViewController(controller, animated: true)
//                        }
//                    })
//                    
//                } else {
//                    let errorString = "Error: Search failed: \(error!.localizedDescription)"
//                    print(errorString)
//                    
//                    self.activityIndicator.stopAnimating()
//                    self.alertMessage = errorString
//                    self.alertUser()
//                }
//                
//            
//        }
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
