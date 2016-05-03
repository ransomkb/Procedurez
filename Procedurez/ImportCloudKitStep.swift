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

class ImportCloudKitStep: UIViewController, UITableViewDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
        }
    }
    
    let alertTitle = "Alert"
    var alertMessage: String?
    
    //var ckStep: CKRecord?
    //var childrenArray: [CKRecord]?
    
    struct ImportCKStrings {
        static let CKChildCellIdentifier = "CKChildCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //CKReference(recordID: CKRecordID(recordName: CloudDictValues.Grandpa), action: .None).recordID

        let reference = CKReference(record: NetLoader.sharedInstance().stepRecord!, action: .DeleteSelf)
        
        NetLoader.sharedInstance().queryChildrenRecords(reference) { (success, error) in
            if error == nil {
                print("Got children")
            } else {
                self.alertMessage = "Error: Search failed: \(error!.localizedDescription)"
                self.alertUser()
            }
        }
    }
    
    
    
    // Use an UIAlertController to inform user of issue.
    func alertUser() {
        
        // Use the main queue to ensure speed.
        dispatch_async(dispatch_get_main_queue(), {
            
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
