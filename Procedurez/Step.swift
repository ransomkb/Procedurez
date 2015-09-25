//
//  Step.swift
//  Procedurez
//
//  Created by Ransom Barber on 9/7/15.
//  Copyright (c) 2015 Ransom Barber. All rights reserved.
//
// Model for entity object

import Foundation
import CoreData

//@objc(Step)

class Step: NSManagedObject {
    
    struct Keys {
        static let Position = "position"
        static let Title = "title"
        static let Details = "details"
    }
    
    @NSManaged var position: Int32
    @NSManaged var title: String
    @NSManaged var details: String
    @NSManaged var done: Bool
    
    @NSManaged var procedure: Procedure
    @NSManaged var parent: Step
    @NSManaged var children: [Step]
    
    // Initiate the parent class with the entity and context.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // Use a convenience initializer.
    init(context: NSManagedObjectContext) {
        
        // Fetch the entity named Pin.
        let entity =  NSEntityDescription.entityForName("Step", inManagedObjectContext: context)!
        
        // Initiate the parent class with the entity and context.
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        title = "Tap to Edit Name"
        details = "Add a short description"
        done = false
        
    }
    
    // Use a convenience initializer to prepare parent and properties.
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Fetch the entity named Pin.
        let entity =  NSEntityDescription.entityForName("Step", inManagedObjectContext: context)!
        
        // Initiate the parent class with the entity and context.
        super.init(entity: entity, insertIntoManagedObjectContext: context)

        //position = 1 //dictionary[Keys.Position] as! Int
        title = dictionary[Keys.Title] as! String
        details = dictionary[Keys.Details] as! String
        done = false
    }
}

