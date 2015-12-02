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

class Step: NSManagedObject {
    
    struct Keys {
        static let Position = "position"
        static let SectionIdentifier = "sectionIdentifier"
        static let Title = "title"
        static let Details = "details"
        static let Parent = "parent"
        static let Children = "children"
    }
    
    @NSManaged var position: Int32
    @NSManaged var sectionIdentifier: String
    @NSManaged var title: String
    @NSManaged var details: String
    @NSManaged var done: Bool
    
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
        sectionIdentifier = "Do"
    }
    
    // Use a convenience initializer to prepare parent and properties.
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Fetch the entity named Pin.
        let entity =  NSEntityDescription.entityForName("Step", inManagedObjectContext: context)!
        
        // Initiate the parent class with the entity and context.
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        print("Step created with dictionary")

        if let pos = dictionary[Keys.Position] {
            position = Int32(pos as! Int)
        }
        
        title = dictionary[Keys.Title] as! String
        details = dictionary[Keys.Details] as! String
        done = false
        sectionIdentifier = "Do"
    }
    
    
    internal func updateSectionIdentifier() {
        sectionIdentifier = sectionForCurrentState()
        print("Step sectionIdentifier: \(sectionIdentifier)")
    }
    
    private func sectionForCurrentState() -> String {
        if done.boolValue {
            return "Done"
        } else {
            return "Do"
        }
    }
    
    //Creates a string in a JSON dictionary format.
    func getJSONDictionary() -> String {
        var json: String
        
        json = "{\"title\":\"\(replaceDoubleQuotes(title))\", " +
            "\"details\":\"\(replaceDoubleQuotes(details))\", " +
            "\"position\":\(position), " +
            "\"sectionIdentifier\":\"\(sectionIdentifier)\", " +
            "\"steps\": \(getJSONArrayOfSteps())}"
        
        return json
    }

    //Creates a string of Step object data in a JSON array format.
    func getJSONArrayOfSteps() -> String {
        var json = "["
        var counter = 0
        
        if !children.isEmpty {
            for child in children {
                json += "\(child.getJSONDictionary())"
                
                if counter < children.count-1 {
                    json += ", "
                }
                
                ++counter
            }
        }
        
        json += "]"
        
        return json
    }
    
    // MARK: - String related
    
    // Replace escaped double-quotes with escaped single-quotes.
    func replaceDoubleQuotes(jsonString: String) -> String {
        return String(jsonString.characters.map {
                //$0 == "\"" ? "\'" : $0
            switch $0 {
            case "\"":
                return "\'"
            default:
                return $0
            }
        })
    }
    
}

