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

@objc(Step)

class Step: NSManagedObject {
    
    struct Keys {
        static let Position = "position"
        static let Name = "name"
        static let Details = "details"
    }
    
    @NSManaged var position: Int
    @NSManaged var name: String
    @NSManaged var details: String
    
    @NSManaged var procedure: Procedure
    @NSManaged var parent: Step
    @NSManaged var children: [Step]
    
    // Initiate the parent class with the entity and context.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // Use a convenience initializer to prepare parent and properties.
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Fetch the entity named Pin.
        let entity =  NSEntityDescription.entityForName("Step", inManagedObjectContext: context)!
        
        // Initiate the parent class with the entity and context.
        super.init(entity: entity, insertIntoManagedObjectContext: context)

        position = dictionary[Keys.Position] as! Int
        name = dictionary[Keys.Name] as! String
        details = dictionary[Keys.Details] as! String
    }
}

