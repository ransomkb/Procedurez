//
//  NetLoader.swift
//  Procedurez
//
//  Created by Ransom Barber on 10/28/15.
//  Copyright © 2015 Ransom Barber. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class NetLoader: NSObject, NSFetchedResultsController {
    var session: NSURLSession
    var searchTask: NSURLSessionDataTask?
    var alertMessage: String?
    
    // Computed property for a shared context of Core Data.
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }

}
