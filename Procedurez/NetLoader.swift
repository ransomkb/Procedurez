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

class NetLoader: NSObject, NSFetchedResultsControllerDelegate {
    
    typealias CompletionHandler = (parsedResult: AnyObject!, error: NSError?) -> Void
    
    var session: NSURLSession
    var searchTask: NSURLSessionDataTask?
    var alertMessage: String = ""
    
    var json: String?
    
    // Computed property for a shared context of Core Data.
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        print("Accessing the Master fetched results controller")
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("Step", inManagedObjectContext: sharedContext)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        //_ = [sortDescriptor]
        
        let predicate = NSPredicate(format: "parent == nil")
        
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        var error: NSError? = nil
        do {
            try _fetchedResultsController!.performFetch()
        } catch let error1 as NSError {
            error = error1
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            print("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil

    
    // Create an error with json data from the response.
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        print("Handling Error")
        
        // Check that there is a dictionary of json data.
        if let parsedResult = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as? [String : AnyObject] {
            
            // Check that there is a key correspoding to the error status message.
            if let errorMessage = parsedResult[Keys.ErrorStatusMessage] as? String {
                
                // Localize the error message.
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                
                // Return the error details.
                return NSError(domain: "PinPhotos Error", code: 1, userInfo: userInfo)
            }
        }
        
        // Return original error as there was no json data.
        return error
    }
    
    // MARK: - JSONParsing stuff
    
    /* Path for JSON files bundled with the Playground */
    //var pathForProcedureJSON = NSBundle.mainBundle().pathForResource("Text Field JSON 1", ofType: "json")
    
    /* Raw JSON data (...simliar to the format you might receive from the network) */
    //var rawAnimalsJSON = NSData(contentsOfFile: pathForProcedureJSON!)
    func importJSON() {
        let rawAnimalsJSON = json!.dataUsingEncoding(NSUTF8StringEncoding)
        
        /* Error object */
        //var parsingAnimalsError: NSError? = nil
        
        /* Parse the data into usable form */
        let parsedProcedureJSON = try! NSJSONSerialization.JSONObjectWithData(rawAnimalsJSON!, options: .AllowFragments) as! NSDictionary
        
        parseJSONAsDictionary(parsedProcedureJSON)
    }
    
    
    func parseJSONAsDictionary(dict: NSDictionary) {
        /* Start playing with JSON here... */
        let dictionary = dict as! [String: AnyObject]
        
        if let title = dictionary["title"] {
            print(title)
        }
        
        if let details = dictionary["details"] {
            print(details)
        }
        
        if let sectionIdentifier = dictionary["sectionIdentifier"] {
            print(sectionIdentifier)
        }
        
        if let position = dictionary["position"] {
            print(position)
        }
        
        if let st = dictionary["steps"] {
            let sArray = st as! [[String: AnyObject]]
            print(sArray)
        }
        
    }



    // Parse JSON data using a completion handler to return the results.
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHandler) {
        
        print("Parsing JSON")
        var parsingError: NSError? = nil
        
        // Parse the json data in the response result.
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        print("Parsed Result: \(parsedResult)")
        
        // Check for a parsing error.
        if let error = parsingError {
            
            // Report the failure and the parsing error.
            completionHandler(parsedResult: nil, error: error)
        } else {
            
            // Return parsed results.
            completionHandler(parsedResult: parsedResult, error: nil)
        }
    }
    
    // Escape the parameters dictionary objects to create a string suitable for the url of a RESTful request.
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        print("Escaping Parameters")
        
        // Create an array of string variables for the url.
        var urlVars = [String]()
        
        // Iterate through the parameters dictionary.
        for (key, value) in parameters {
            
            // Ensure the values are strings.
            let stringValue: String = value as! String
            
            // Use percent encoding to escape difficult characters.
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            // Create the key / value pair and add it to the array of url variables.
            let requestSnippet = key + "=" + "\(escapedValue!)"
            //println(requestSnippet)
            urlVars += [requestSnippet]
        }
        
        // Return string of joined url variables separated by &.
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    // MARK: - Shared Instance
    
    // Create a shared instance singleton for PinPhotos.
    class func sharedInstance() -> NetLoader {
        
        struct Singleton {
            static var sharedInstance = NetLoader()
        }
        
        return Singleton.sharedInstance
    }
    
    // MARK: - Shared Image Cache
    
    // Creates a shared image cache.
    struct Caches {
        static let procedureCache = ProcedureCache()
    }
    
}
