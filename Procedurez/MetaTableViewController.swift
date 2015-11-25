//
//  MetaTableViewController.swift
//  Procedurez
//
//  Created by Ransom Barber on 11/9/15.
//  Copyright © 2015 Ransom Barber. All rights reserved.
//

import Foundation
import UIKit

class MetaTableViewController: UITableViewController {
    
    var alertMessage: String?
    
    var proceduresMeta: [ParseProcedure] = []
    
    @IBOutlet weak var tableViewCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "segueToImport")
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            NetLoader.sharedInstance().isMeta = true
            NetLoader.sharedInstance().searchParse { (success, errorString) -> Void in
                if success {
                    print("Finished getting array of meta items.")
                    self.proceduresMeta = NetLoader.sharedInstance().metaArray
                    self.tableView.reloadData()
                } else {
                    print(errorString)
                    
                    self.alertMessage = errorString
                    self.alertUser()
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
    }
    
    @IBAction func segueToImport() {
        let navigationController = splitViewController!.viewControllers[splitViewController!.viewControllers.count-1] as! UINavigationController
        let controller = self.storyboard?.instantiateViewControllerWithIdentifier("ImportStringViewController") as! ImportStringViewController
        NetLoader.sharedInstance().isSegue = false
        navigationController.pushViewController(controller, animated: true)
    }
    
    
    // MARK: - Table view functions
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return NetLoader.sharedInstance().metaArray.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MetaCell", forIndexPath: indexPath) as UITableViewCell
        let meta = NetLoader.sharedInstance().metaArray[indexPath.row]
        
        cell.textLabel?.text = "\(meta.name)"
        cell.detailTextLabel?.text = "Created by \(meta.creator)"
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let navigationController = splitViewController!.viewControllers[splitViewController!.viewControllers.count-1] as? UINavigationController {
            let controller = self.storyboard?.instantiateViewControllerWithIdentifier("ImportStringViewController") as! ImportStringViewController
            NetLoader.sharedInstance().parseProcedure = proceduresMeta[indexPath.row]
            NetLoader.sharedInstance().isSegue = true
            navigationController.pushViewController(controller, animated: true)
        }
    }
    
    // MARK: - Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        print("Preparing for Segue to ImportString")
        if segue.identifier == "showImportFromCell" {
            print("Have a segue identifier called showImport")
            if let indexPath = self.tableView.indexPathForSelectedRow {

                NetLoader.sharedInstance().parseProcedure = proceduresMeta[indexPath.row]
                NetLoader.sharedInstance().isSegue = true
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
