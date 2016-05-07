//
//  ImportCloudKitStep.swift
//  Procedurez
//
//  Created by Ransom Barber on 5/3/16.
//  Copyright © 2016 Ransom Barber. All rights reserved.
//

import UIKit
import Foundation
import CloudKit

class ImportCloudKitStep: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var subStepsLabel: UILabel!

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
        }
    }
    
    let alertTitle = "Alert"
    var alertMessage: String?
    
    var ckStep: CKRecord?
    var childrenArray: [CKRecord]?
    
    struct ImportCKStrings {
        static let CKChildCellIdentifier = "CKChildCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add a button for creating substeps / children.
        let shareButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: #selector(ImportCloudKitStep.saveAction(_:)))
        
//        // Add a share button if this is the first Step.
//        let rightBarButtonItems: [UIBarButtonItem]!
//        if (detailItem?.parent == nil) {
//            rightBarButtonItems = [addButton, shareButton]
//        } else {
//            rightBarButtonItems = [addButton]
//        }
        
        //self.navigationItem.rightBarButtonItems = rightBarButtonItems
        self.navigationItem.rightBarButtonItem = shareButton

        
        self.subStepsLabel.hidden = true
        self.activityIndicator.startAnimating()
        
        self.childrenArray = [CKRecord]()
        
        NetLoader.sharedInstance().recordArray.removeAll()
        
        let reference = CKReference(record: self.ckStep!, action: .DeleteSelf)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            
            NetLoader.sharedInstance().queryChildrenRecords(reference) { (success, error) in
                dispatch_async(dispatch_get_main_queue(), {
                    
                    if error != nil {
                        self.alertMessage = "Error: Search failed: \(error!.localizedDescription)"
                        self.alertUser()
                    } else if success {
                        self.activityIndicator.stopAnimating()
                        print("Got children")
                        self.childrenArray = NetLoader.sharedInstance().recordArray
                        self.tableView.reloadData()
                    } else {
                        self.subStepsLabel.hidden = false
                    }
                })
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        titleLabel.text = ckStep!["title"] as? String
        detailsLabel.text = ckStep!["details"] as? String
    }
    
    func saveAction(sender: AnyObject) {
        
        self.alertMessage = "Do you wish to save this Procedure of Steps to Local Storage?"
        
        // Create an instance of UIAlertController.
        let alertController = UIAlertController(title: self.alertTitle, message: self.alertMessage, preferredStyle: .Alert)
        
        // Create action button with OK button to dismiss alert.
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action) -> Void in
            // save the ckStep to Core Data
            NetLoader.sharedInstance().isImporting = true
            // save
            self.downLoadCKStep()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        // Add the OK action.
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        // Present the alert controller.
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func downLoadCKStep() {
        NetLoader.sharedInstance().loadCKProcedureIntoCoreData(NetLoader.sharedInstance().stepRecord!, lckpCompletionHandler: { (success, error) in
            
            dispatch_async(dispatch_get_main_queue(), {
                if error == nil {
                    CoreDataStackManager.sharedInstance().saveContext()
                    //                        do {
                    //                            try NetLoader.sharedInstance().sharedContext.save()
                    //                            let message = "Successful Save!"
                    //                            print(message)
                    //                            self.alertMessage = message
                    //                        } catch {
                    //                            fatalError("Failure to save sharedContext: \(error)")
                    //                        }
                    let message = "Successful Save!"
                    print(message)
                    self.alertMessage = message
                    print("Successful return to downLoadCKStep")
                    NetLoader.sharedInstance().isImporting = false
                } else {
                    self.alertMessage = "There was an error: \(error?.localizedDescription)"
                }
            })
            
            self.alertUser()
        })
    }
    
    // MARK: - Table View
    
    // Return 1 as there will only ever be 1 section.
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // Return the count of the recordArray property in NetLoader.
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return childrenArray!.count
    }
    
    // Return a cell configured to the title and details of a Step.
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Dequeue a cell and get the appropriate data from the array.
        let cell = tableView.dequeueReusableCellWithIdentifier(ImportCKStrings.CKChildCellIdentifier, forIndexPath: indexPath) as UITableViewCell
        let step = childrenArray![indexPath.row]
        
        cell.textLabel?.text = step["title"]! as? String
        cell.detailTextLabel?.text = step["details"] as? String
        return cell
    }
    
    // Segue to ImportStringViewController if a cell is selected.
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        dispatch_async(dispatch_get_main_queue(), {
            
            if let navigationController = self.splitViewController!.viewControllers[self.splitViewController!.viewControllers.count-1] as? UINavigationController {
                let controller = self.storyboard?.instantiateViewControllerWithIdentifier("ImportCloudKitStep") as! ImportCloudKitStep
                
                controller.ckStep = self.childrenArray![indexPath.row]
                
                NetLoader.sharedInstance().isSegue = true
                navigationController.pushViewController(controller, animated: true)
            }
        })
    }
    
    
    // MARK: - Alert Controller
    
    // Use an UIAlertController to inform user of issue.
    func alertUser() {
        
        // Use the main queue to ensure speed.
        dispatch_async(dispatch_get_main_queue(), {
            
            self.activityIndicator.stopAnimating()
            
            // Create an instance of UIAlertController.
            let alertController = UIAlertController(title: self.alertTitle, message: self.alertMessage, preferredStyle: .Alert)
            
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
