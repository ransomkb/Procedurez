//
//  ImportStringViewController.swift
//  Procedurez
//
//  Created by Ransom Barber on 10/30/15.
//  Copyright © 2015 Ransom Barber. All rights reserved.
//

import UIKit
import Foundation

// View Controller for importing Procedures in a JSON formatted string.
class ImportStringViewController: UIViewController, UITextViewDelegate {
    
    var JSONString: String?
    var alertTitle: String?
    var alertMessage: String?
    
    /* Based on student comments, this was added to help with smaller resolution devices */
    var keyboardAdjusted = false
    var lastKeyboardOffset: CGFloat = 0.0
    
    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var importTextView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // Saves the text view string as one or more Step entities in CoreData with paent / child relationships.
    @IBAction func saveJSONString(sender: AnyObject) {
        
        self.activityIndicator.startAnimating()
        
        // Set the string properties.
        JSONString = importTextView.text
        NetLoader.sharedInstance().json = JSONString
        
        // Verify / Vet and save to CoreData.
        NetLoader.sharedInstance().importJSON(JSONString!) { (success, errorString) -> Void in
            if success {
                self.activityIndicator.stopAnimating()
                self.alertTitle = "FYI"
                self.alertMessage = "Import Succeeded"
                self.alertUser()
            } else {
                self.activityIndicator.stopAnimating()
                self.alertTitle = "Had an Issue"
                self.alertMessage = errorString
                self.alertUser()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Resign first responder when tapping anywhere else.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ImportStringViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // Set self as text view delegate.
        self.importTextView.delegate = self
        
        // Add default text to text view.
        importTextView.text = "Paste Copied JSON Here"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //self.addKeyboardDismissRecognizer()
        self.subscribeToKeyboardNotifications()
        
        // Ensure segue was from a Parse.com data related table cell.
        if NetLoader.sharedInstance().isSegue {
            print("Segued to ImportString via Cell")
            
            self.activityIndicator.startAnimating()
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                
                // Find the correct data on Parse.com.
                NetLoader.sharedInstance().searchParse({ (success, errorString) -> Void in
                    if success {
                        print("Got the Procedure Steps")
                        
                        // Display the JSON formatted data from Parse.com in the text view.
                        self.importTextView.text = NetLoader.sharedInstance().parseProcedure?.steps
                    } else {
                        print(errorString)
                        
                        self.alertMessage = errorString
                        self.alertUser()
                    }
                })
            }
        } else {
            print("Segued to ImportString via Add button")
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //self.removeKeyboardDismissRecognizer()
        self.unsubscribeToKeyboardNotifications()
    }
    
    // MARK: - TextView related
    
    // Remove default text.
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


/* This code has been added in response to student comments */
extension ImportStringViewController {
    
    func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ImportStringViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ImportStringViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        
        if keyboardAdjusted == false {
            lastKeyboardOffset = getKeyboardHeight(notification) / 2
            self.view.superview?.frame.origin.y = -lastKeyboardOffset
            keyboardAdjusted = true
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        if keyboardAdjusted == true {
            self.view.superview?.frame.origin.y = 0.0
            keyboardAdjusted = false
        }
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.CGRectValue().height
    }
}

