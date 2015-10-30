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
    
    @IBOutlet weak var explanationLabel: UILabel!
    @IBOutlet weak var importTextView: UITextView!
    
    @IBAction func saveJSONString(sender: AnyObject) {
        JSONString = importTextView.text
        NetLoader.sharedInstance().json = JSONString
        
        NetLoader.sharedInstance().importJSON()
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
    
}
