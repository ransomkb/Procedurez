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
    
    var procedureID: String?
    var metaID: String?
    
    var isMeta: Bool
    var isSegue: Bool = false
    
    var metaArray: [ParseProcedure]
    var parseProcedure: ParseProcedure?
    
    var alertMessage: String = ""
    
    var json: String?
    
    let titleCount = 50
    let detailsCount = 140
    let sectionIdentifierCount = 4
    
    
    // Computed property for a shared context of Core Data.
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    override init() {
        session = NSURLSession.sharedSession()
        isMeta = true
        metaArray = [ParseProcedure]()
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

    // Search for a dictionary with student location details on Udacity site.
    func searchParse(completionHandler: (success: Bool, errorString: String?) -> Void) {
        // Use the GET method for a RESTful request.
        taskForGETMethod(API.ParseBaseURL, method: self.setParseClass(), requestValues: NetLoader.setREST()) { (JSONResult, error) -> Void in
            
            if let error = error {
                // Report JSONResult error details in completion handler.
                completionHandler(success: false, errorString: "Error: Search failed. (Existing Procedure). \(error.localizedDescription)")
            } else {
                print("No Error in Search")
                
                // Check if dictionary of results exists in parsed JSON data.
                if let resultsArray = JSONResult.valueForKey(NetLoader.JSONResponseKeys.Results) as? [[String:AnyObject]] {
                    print("Got Existing Procedure.")
                    
                    // Check if dictionary of results is empty.
                    if resultsArray.count > 0 {
                        print("Results count: \(resultsArray.count)")
                        
                        
                        if self.isMeta {
                            
                            self.metaArray = [ParseProcedure]()
                            
                            for meta in resultsArray {
                                print("Got some Meta: \(meta)")
                                let metaProcedure = ParseProcedure(dictionary: meta as [String:AnyObject])
                                self.metaArray.append(metaProcedure)
                                //return photo
                            }
                            
                            print("metaArray.count: \(self.metaArray.count)")
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                //self.procedureID = self.metaArray[0].procedureId
                                self.isMeta = false
                                // Use completion handler to report successful creation.
                                completionHandler(success: true, errorString: nil)
                            })
                            
                        } else {
                            print("metaArray is not empty; getting steps")
                            
                            let dictionary: [String:AnyObject] = resultsArray[0]
                            
                            if let process = self.parseProcedure {
                                if let objectID = dictionary["objectId"] as? String {
                                    print("Procedure JSON has an objectId.")
                                    if (objectID == process.procedureId) {
                                        print("Procedure objectId == meta.procedureId")
                                        if let procedureSteps = dictionary["steps"] as? String {
                                            print("JSON dictionary key steps was assigned to a ParseProcedure.steps")
                                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                                
                                                self.parseProcedure?.steps = procedureSteps
                                                print("\(self.parseProcedure?.steps)")
                                                // Use completion handler to report successful creation.
                                                completionHandler(success: true, errorString: nil)
                                            })
                                        }
                                    }
                                }

                            }
//                            
//                            for meta in self.metaArray as [ParseProcedure] {
//                                                            }
                            
                        }
                        
                        // Use completion handler to report successful creation.
                        //completionHandler(success: true, errorString: nil)
                        
                        
                    } else {
                        
                        // Use completion handler to report unlikely situation: there is a dictionary of results, but it is empty.
                        let eString = "results count is 0 or less."
                        completionHandler(success: true, errorString: eString)
                    }
                } else {
                    
                    // Use completion handler to report no error, but no student locations returned for user, so probably first time.
                    let eString = "Existing Procedure not found."
                    completionHandler(success: true, errorString: eString)
                }
            }
        }
    }
    
    // Create a task using the GET method; handle JSON response.
    func taskForGETMethod(baseURL: String, method: String, requestValues: [[String:String]], completionHandler: (result: AnyObject!, error: NSError?) -> Void ) -> NSURLSessionDataTask {
        
        // Create a string of parameters for RESTful request.
        
        let urlString: String!
        
        // Create request from URL.
        if isMeta {
            urlString = baseURL + method
        } else {
            
            guard let _ = self.parseProcedure!.procedureId else {
                let eString = "procedureID had an issue."
                print(eString)
                
                return self.searchTask!
            }
            
            urlString = baseURL + method + NetLoader.substituteKeyInMethod(NetLoader.Values.SpecificProcedure, key: NetLoader.Values.Key, value: (self.parseProcedure?.procedureId!)!)!
        }
        
        print("GET URL: \(urlString)")
        
        guard let url = NSURL(string: urlString) else {
            let eString = "urlString had an issue."
            print(eString)
            
            return self.searchTask!
        }
        
        let request = NSMutableURLRequest(URL: url)
        
        // Add request values to dictionary if they are used in this request.
        if !requestValues.isEmpty {
            for dict in requestValues {
                request.addValue(dict["value"]!, forHTTPHeaderField: dict["field"]!)
            }
        }
        
        // Create a data task with a request for shared session; pass response data to JSON parser.
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, downloadError) -> Void in
            
            print("Starting GET task.")
            
            // Handle download error.
            if let error = downloadError {
                let newError = NetLoader.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: newError)
            } else {
                print("No Error, Time to Parse Data.")
                
                //let newData = data
                
//                // Get a subset of the data to conform to Udacity requirements, if udacity Bool is true.
//                if udacity {
//                    print("udacity was true, so getting subset of data.")
//                    /* subset response data! */
//                    newData = data!.subdataWithRange(NSMakeRange(5, data!.length - 5))
//                }
                
                
                //println("JSONResult data: \(NSString(data: newData, encoding: NSUTF8StringEncoding)!)")
                
                // Send data to shared JSON parser.
                NetLoader.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
            }
        })
        
        task.resume()
        
        return task
    }

    class func setREST() -> [[String:String]]{
        print("Setting REST values")
        
        // Create a dictionary to hold values for request.
        var requestValues = [[String:String]]()
        requestValues.append([Keys.Value : Values.ApplicationID, Keys.Field : Values.ParseAppIDField])
        requestValues.append([Keys.Value : Values.RESTAPIKey, Keys.Field : Values.RESTAPIField])
        requestValues.append([Keys.Value : Values.ApplicationJSON, Keys.Field : Values.ContentType])
        
        return requestValues
    }
    
    func setParseClass() -> String {
        if isMeta {
            print("Parse Class is Meta")
            return API.Meta
        } else {
            print("Parse Class is Procedure")
            return API.Procedure
        }
    }
    
    // Create an error with json data from the response.
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        print("Handling Error")
        
        let nsError = error
        
        // Check that there is a dictionary of json data.
//        if let parsedResult = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as? [String : AnyObject] {
        do {
            if let jsonData = data {
                
                let parsedResult = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.AllowFragments) as? [String : AnyObject]
                
                // Check that there is a key correspoding to the error status message.
                if let errorMessage = parsedResult![Keys.ErrorStatusMessage] as? String {
                    
                    // Localize the error message.
                    let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                    
                    // Return the error details.
                    return NSError(domain: "PinPhotos Error", code: 1, userInfo: userInfo)
                }
            }
        } catch {
            // Return original error as there was no json data.
           print("Internet connection FAILED: \(error)")
        }
        
        return nsError
    }
    
    // Class method for replacing a variable with a string value in a task method
    class func substituteKeyInMethod(method: String, key: String, value: String) -> String? {
        if method.rangeOfString("\(key)") != nil {
            print(method)
            return method.stringByReplacingOccurrencesOfString("\(key)", withString: value)
        } else {
            return nil
        }
    }
    
    // MARK: - JSONParsing stuff
    
    // IMPORTANT: get the LoadMe file from the bundle. parse the jason and set the first how to.
    func loadHowTo(jsonData: NSData, completionhandler: (success: Bool, errorString: String?) -> Void) {
        
        print("Trying to load How to Use Procedure.")
        
        NetLoader.parseJSONWithCompletionHandler(jsonData) { (parsedResult, error) -> Void in
            
            if let error = error {
                print("Error in Parsing with rawProcedureJSON data.")
                completionhandler(success: false, errorString: error.localizedDescription)
            } else {
                print("Parsed JSON data successfully.")
                self.parseJSONAsDictionary(parsedResult as! NSDictionary, parent: nil, completionhandler: { (success, errorString) -> Void in
                    if let error = errorString {
                        completionhandler(success: false, errorString: error)
                    } else {
                        do {
                            try self.sharedContext.save()
                        } catch {
                            fatalError("Failure to save context: \(error)")
                        }
                        
                        completionhandler(success: true, errorString: nil)
                    }
                })
            }
        }

    }
    
    /* Path for JSON files bundled with the Playground */
    //var pathForProcedureJSON = NSBundle.mainBundle().pathForResource("Text Field JSON 1", ofType: "json")
    
    
    /* Raw JSON data (...simliar to the format you might receive from the network) */
    //var rawAnimalsJSON = NSData(contentsOfFile: pathForProcedureJSON!)
    
    
    func importJSON(jsonString: String, completionhandler: (success: Bool, errorString: String?) -> Void) {
        print("Importing ProcedureJSON")
        
        let rawProcedureJSON = json!.dataUsingEncoding(NSUTF8StringEncoding)
        
        self.loadHowTo(rawProcedureJSON!) { (success, errorString) -> Void in
            if success {
                completionhandler(success: true, errorString: nil)
            } else {
                completionhandler(success: false, errorString: errorString)
            }
        }
        
//        NetLoader.parseJSONWithCompletionHandler(rawProcedureJSON!) { (parsedResult, error) -> Void in
//            
//            if let error = error {
//                print("Error in Parsing with rawProcedureJSON data.")
//                completionhandler(success: false, errorString: error.localizedDescription)
//            } else {
//                print("Parsed JSON data successfully.")
//                self.parseJSONAsDictionary(parsedResult as! NSDictionary, parent: nil, completionhandler: { (success, errorString) -> Void in
//                    if let error = errorString {
//                        completionhandler(success: false, errorString: error)
//                    } else {
//                        do {
//                            try self.sharedContext.save()
//                        } catch {
//                            fatalError("Failure to save context: \(error)")
//                        }
//
//                        completionhandler(success: true, errorString: nil)
//                    }
//                })
//            }
//        }
        
//        do {
//            /* Parse the data into usable form */
//            let parsedProcedureJSON = try NSJSONSerialization.JSONObjectWithData(rawProcedureJSON!, options: .AllowFragments) as! NSDictionary
//            
//            parseJSONAsDictionary(parsedProcedureJSON)
//        } catch {
//            print("Caught an error while parsing JSON: \(error)")
//        }
    }
    
    
    func parseJSONAsDictionary(dict: NSDictionary, parent: Step?, completionhandler: (success: Bool, errorString: String?) -> Void) {
        
        /* Start playing with JSON here... */
        print("Parsing a JSON Dictionary to creat a Step in a Procedure.")
        
        let dictionary = dict as! [String: AnyObject]
        
        guard let title = dictionary["title"] where (dictionary["title"] as! String).characters.count <= self.titleCount else {
            let eString = "Dictionary had no title key."
            completionhandler(success: false, errorString: eString)
            return
        }
        
        guard let details = dictionary["details"] where (dictionary["details"]as! String).characters.count <= self.detailsCount else {
            let eString = "Dictionary had no details key."
            completionhandler(success: false, errorString: eString)
            return
        }
        
        guard let sectionIdentifier = dictionary["sectionIdentifier"] where (dictionary["sectionIdentifier"] as! String).characters.count <= self.sectionIdentifierCount else {
            let eString = "Dictionary had no sectionIdentifier key."
            completionhandler(success: false, errorString: eString)
            return
        }
        
        guard let position = dictionary["position"] else {
            let eString = "Dictionary had no position key."
            completionhandler(success: false, errorString: eString)
            return
        }
        
        guard let st = dictionary["steps"] else {
            let eString = "Dictionary had no steps key."
            completionhandler(success: false, errorString: eString)
            return
        }
        
        print("Title: \(title)")
        print("Details: \(details)")
        print("SectionIdentifier: \(sectionIdentifier)")
        print("Position: \(position)")
        print("Steps: Have an array")
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            let step = Step(dictionary: dictionary, context: self.sharedContext)
            
            if let p = parent {
                step.parent = p
            }
            
            let sArray = st as! [[String: AnyObject]]
            // print("Array of Steps: \(sArray)")
            
            for d in sArray {
                self.parseJSONAsDictionary(d, parent: step, completionhandler: { (success, errorString) -> Void in
                    if success {
                        print("Made a Step")
                    } else {
                        print("Had an error")
                    }
                })
            }
            
            
        })
        
        completionhandler(success: true, errorString: nil)
        
        
        //        if let title = dictionary["title"] {
        //            print("Title: \(title)")
        //
        //            if let details = dictionary["details"] {
        //                print("Details: \(details)")
        //
        //                if let sectionIdentifier = dictionary["sectionIdentifier"] {
        //                    print("SectionIdentifier: \(sectionIdentifier)")
        //
        //                    if let position = dictionary["position"] {
        //                        print("Position: \(position)")
        //                        if let st = dictionary["steps"] {
        //                         // Get Main Queue for context.
        //                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
        //
        //                                let step = Step(dictionary: dictionary, context: self.sharedContext)
        //
        //                                if let p = parent {
        //                                    step.parent = p
        //                                }
        //
        //                                let sArray = st as! [[String: AnyObject]]
        //                                // print("Array of Steps: \(sArray)")
        //
        //                                for d in sArray {
        //                                    self.parseJSONAsDictionary(d, parent: step, completionhandler: { (success, errorString) -> Void in
        //                                        if success {
        //                                            print("Made a Step")
        //                                        } else {
        //                                            print("Had an error")
        //                                        }
        //                                    })
        //                                }
        //
        //
        //                                // Create a Photo class and entity value for each photo in the array using its dictionary.
        //                                //                            _ = sArray.map() {(dictionary: [String : AnyObject]) -> Step in
        //                                //
        //                                //
        //                                //                                // Set the pin variable in photo to that passed through this function.
        //                                //                                photo.pin = pin
        //                                //                                print("Photo image path: \(photo.imagePath)")
        //                                //                                return step
        //                                //                            }
        //
        //                                // IMPORTANT: uncomment this to save context, after finish iterating stuff.
        //                                //                            do {
        //                                //                                try self.sharedContext.save()
        //                                //                            } catch {
        //                                //                                fatalError("Failure to save context: \(error)")
        //                                //                            }
        //                            })
        //
        //                            completionhandler(success: true, errorString: nil)
        //                        } else {
        //                            let eString = "Dictionary had no steps key."
        //                            completionhandler(success: false, errorString: eString)
        //                        }
        //                    } else {
        //                        let eString = "Dictionary had no position key."
        //                        completionhandler(success: false, errorString: eString)
        //                    }
        //                } else {
        //                    let eString = "Dictionary had no sectionIdentifier key."
        //                    completionhandler(success: false, errorString: eString)
        //                }
        //            } else {
        //                let eString = "Dictionary had no details key."
        //                completionhandler(success: false, errorString: eString)
        //            }
        //        } else {
        //            let eString = "Dictionary had no title key."
        //            completionhandler(success: false, errorString: eString)
        //        }
        //        
        
        //        if let error = errorString as String {
        //            print("Error in Parsing with rawProcedureJSON data.")
        //            completionhandler(success: false, errorString: error.localized)
        //        } else {
        //            print("Parsed JSON data successfully.")
        //        }
        
    }

    
//    
//    func parseJSONAsDictionary(dict: NSDictionary, parent: Step?, completionhandler: (success: Bool, errorString: String?) -> Void) {
//        /* Start playing with JSON here... */
//        print("Parsing a JSON Dictionary to creat a Step in a Procedure.")
//        
//        let dictionary = dict as! [String: AnyObject]
//        
//        if let title = dictionary["title"] {
//            print("Title: \(title)")
//            
//            if let details = dictionary["details"] {
//                print("Details: \(details)")
//                
//                if let sectionIdentifier = dictionary["sectionIdentifier"] {
//                    print("SectionIdentifier: \(sectionIdentifier)")
//                    
//                    if let position = dictionary["position"] {
//                        print("Position: \(position)")
//                        if let st = dictionary["steps"] {
//                         // Get Main Queue for context.
//                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                                
//                                let step = Step(dictionary: dictionary, context: self.sharedContext)
//                                
//                                if let p = parent {
//                                    step.parent = p
//                                }
//                                
//                                let sArray = st as! [[String: AnyObject]]
//                                // print("Array of Steps: \(sArray)")
//                                
//                                for d in sArray {
//                                    self.parseJSONAsDictionary(d, parent: step, completionhandler: { (success, errorString) -> Void in
//                                        if success {
//                                            print("Made a Step")
//                                        } else {
//                                            print("Had an error")
//                                        }
//                                    })
//                                }
//                                
//                                
//                                // Create a Photo class and entity value for each photo in the array using its dictionary.
//                                //                            _ = sArray.map() {(dictionary: [String : AnyObject]) -> Step in
//                                //
//                                //
//                                //                                // Set the pin variable in photo to that passed through this function.
//                                //                                photo.pin = pin
//                                //                                print("Photo image path: \(photo.imagePath)")
//                                //                                return step
//                                //                            }
//                                
//                                // IMPORTANT: uncomment this to save context, after finish iterating stuff.
//                                //                            do {
//                                //                                try self.sharedContext.save()
//                                //                            } catch {
//                                //                                fatalError("Failure to save context: \(error)")
//                                //                            }
//                            })
//                            
//                            completionhandler(success: true, errorString: nil)
//                        } else {
//                            let eString = "Dictionary had no steps key."
//                            completionhandler(success: false, errorString: eString)
//                        }
//                    } else {
//                        let eString = "Dictionary had no position key."
//                        completionhandler(success: false, errorString: eString)
//                    }
//                } else {
//                    let eString = "Dictionary had no sectionIdentifier key."
//                    completionhandler(success: false, errorString: eString)
//                }
//            } else {
//                let eString = "Dictionary had no details key."
//                completionhandler(success: false, errorString: eString)
//            }
//        } else {
//            let eString = "Dictionary had no title key."
//            completionhandler(success: false, errorString: eString)
//        }
//        
//        
////        if let error = errorString as String {
////            print("Error in Parsing with rawProcedureJSON data.")
////            completionhandler(success: false, errorString: error.localized)
////        } else {
////            print("Parsed JSON data successfully.")
////        }
//        
//    }



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
