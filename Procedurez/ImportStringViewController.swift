//
//  ImportStringViewController.swift
//  Procedurez
//
//  Created by Ransom Barber on 10/30/15.
//  Copyright © 2015 Ransom Barber. All rights reserved.
//

import UIKit
import Foundation

class ImportStringViewController: UIViewController, UITextViewDelegate {
    
    var JSONString: String?
    var alertMessage: String?

    
    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var importTextView: UITextView!
    
    @IBAction func saveJSONString(sender: AnyObject) {
        JSONString = importTextView.text
        NetLoader.sharedInstance().json = JSONString
        
        NetLoader.sharedInstance().importJSON(JSONString!) { (success, errorString) -> Void in
            if success {
                self.alertMessage = "Import Succeeded"
                self.alertUser()
            } else {
                self.alertMessage = errorString
                self.alertUser()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Resign first responder when tapping anywhere else.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
        self.importTextView.delegate = self
        importTextView.text = "Paste Copied JSON Here"
    }
    
    // MARK: - TextView related
    
    func textViewDidBeginEditing(textView: UITextView) {
        print("Did Begin Editing")
        if (self.importTextView.text == "Paste Copied JSON Here") {
            self.importTextView.text = ""
        }
    }
    
    func dismissKeyboard() {
        // Resign the first responder.
        view.endEditing(true)
    }
    
    
    // Use an UIAlertController to inform user of issue.
    func alertUser() {
        
        // Use the main queue to ensure speed.
        dispatch_async(dispatch_get_main_queue(), {
            
            // Create an instance of UIAlertController.
            let alertController = UIAlertController(title: "Alert", message: self.alertMessage, preferredStyle: .Alert)
            
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
