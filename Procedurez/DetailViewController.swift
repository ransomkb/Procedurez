//
//  DetailViewController.swift
//  Procedurez
//
//  Created by Ransom Barber on 9/4/15.
//  Copyright (c) 2015 Ransom Barber. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

   // , UITableViewDelegate, UITableViewDataSource

    @IBOutlet weak var detailDescriptionLabel: UILabel!

    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    
    // Save the new or updated Step.
    @IBAction func saveStep(sender: AnyObject) {
        
    }
    

    func configureView() {
        // Update the user interface for the detail item.
        if let detail: AnyObject = self.detailItem {
            if let label = self.detailDescriptionLabel {
                label.text = detail.valueForKey("name")!.description
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

