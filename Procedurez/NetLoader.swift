//
//  NetLoader.swift
//  Procedurez
//
//  Created by Ransom Barber on 10/28/15.
//  Copyright © 2015 Ransom Barber. All rights reserved.
//

import Foundation
import CloudKit
import CoreData
import MapKit
import UIKit

class NetLoader: NSObject, NSFetchedResultsControllerDelegate {
    
    typealias CompletionHandler = (parsedResult: AnyObject!, error: NSError?) -> Void
    
    let container: CKContainer
    let publicDB: CKDatabase
    let privateDB: CKDatabase
    
    
    
    var session: NSURLSession
    
    // may not be using
    var searchTask: NSURLSessionDataTask?
    
    var isMeta: Bool
    var isSegue: Bool = false
    
    var metaID: String?
    var procedureID: String?
    
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
        container = CKContainer.defaultContainer()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
        session = NSURLSession.sharedSession()
        isMeta = true
        metaArray = [ParseProcedure]()
        super.init()
    }
    
    // Got from Stack Trace?
    //import Foundation
    // Use Below turn JSONData into string
    // var dataString = String(data: fooData, encoding: NSUTF8StringEncoding)
    
    func dictToJSONData(dict:[String: AnyObject]) -> NSData? {
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions.PrettyPrinted)
            
            // Use Below turn JSONData into string; just for reference reminder; place somewhere else
            // var dataString = String(data: jsonData, encoding: NSUTF8StringEncoding)
            
            return jsonData
            // here "jsonData" is the dictionary encoded in JSON data
        } catch let error as NSError {
            print(error)
            return nil
        }
    }
    
    func JSONToDict(jsonData: NSData) -> [String: AnyObject]? {
        do {
            let decoded = try NSJSONSerialization.JSONObjectWithData(jsonData, options: []) as? [String:String]
            // here "decoded" is the dictionary decoded from JSON data
            return decoded!
        } catch let error as NSError {
            print(error)
            return nil
        }
    }
    
    func createUniqueID() -> String {
        let timestampAsString = String(format: "%f", NSDate.timeIntervalSinceReferenceDate())
        let timestampParts = timestampAsString.componentsSeparatedByString(".")
        
        return timestampParts[0]
    }
    
    // Search for a dictionary on Parse.com with details of a Procedure / Procedures.
    func searchParse(completionHandler: (success: Bool, errorString: String?) -> Void) {
        
        // New for CloudKit
        // POST [path]/database/[version]/[container]/[environment]/[database]/[subpath]
//        let baseUrlArray = [API.Path,
//                        "database",
//                        API.Version,
//                        API.Container,
//                        API.EnvironmentDevelopment,
//                        API.PublicDatabase,
//                        SubPaths.Records]
//        
//        let baseURL = buildPath(baseUrlArray)
//        
        
        // Use the GET method for a RESTful request.
        taskForGETMethod(API.ParseBaseURL, method: self.setParseClass(), requestValues: NetLoader.setREST()) { (JSONResult, error) -> Void in
        
        // CloudKit version
        //taskForCKGetMethod(baseURL, method: self.setParseClass()) { (JSONResult, error) -> Void in
            
            if let error = error {
                // Report JSONResult error details in completion handler.
                completionHandler(success: false, errorString: "Error: Search failed: \(error.localizedDescription)")
            } else {
                print("No Error in Search")
                
                // Check if dictionary of results exists in parsed JSON data.
                if let resultsArray = JSONResult.valueForKey(NetLoader.JSONResponseKeys.Results) as? [[String:AnyObject]] {
                    print("Got Existing Procedure.")
                    
                    // Check if dictionary of results is empty.
                    if resultsArray.count > 0 {
                        print("Results count: \(resultsArray.count)")
                        
                        // Get MetaData of a Procedure, or the JSON formatted string of the Procedure itself.
                        if self.isMeta {
                            
                            // Create ParseProcedure objects from the results array, and append them to the meta array.
                            self.metaArray = [ParseProcedure]()
                            
                            for meta in resultsArray {
                                print("Got some Meta: \(meta)")
                                let metaProcedure = ParseProcedure(dictionary: meta as [String:AnyObject])
                                self.metaArray.append(metaProcedure)
                            }
                            
                            print("metaArray.count: \(self.metaArray.count)")

                            // IMPORTANT: see about threading for Core Data on another queue, not Main;
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                
                                self.isMeta = false
                                
                                // Use completion handler to report successful creation.
                                completionHandler(success: true, errorString: nil)
                            })
                        
                        } else {
                            print("metaArray is not empty; getting steps")
                            
                            // Get the single JSON formatted string object from the results array.
                            let dictionary: [String:AnyObject] = resultsArray[0]
                            
                            if let process = self.parseProcedure {
                                if let objectID = dictionary["objectId"] as? String {
                                    print("Procedure JSON has an objectId.")
                                    if (objectID == process.procedureId) {
                                        print("Procedure objectId == meta.procedureId")
                                        if let procedureSteps = dictionary["steps"] as? String {
                                            print("JSON dictionary key steps was assigned to a ParseProcedure.steps")
                                            
                                            // Set the steps property of the parseProecedure to that of the results array.
                                            // IMPORTANT: see about threading for Core Data on another queue, not Main;
                                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                                
                                                self.parseProcedure?.steps = procedureSteps
                                                print("\(self.parseProcedure?.steps)")
                                                // Use completion handler to report successful creation.
                                                completionHandler(success: true, errorString: nil)
                                            })
                                            
                                             //IMPORTANT: Get off the Main Queue when doing Core Data intensive stuff;
                                             //Consider this kind of threading:
//                                            let jsonArray = … //JSON data to be imported into Core Data
//                                            let moc = … //Our primary context on the main queue
//
//                                            let privateMOC = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
//                                            privateMOC.parentContext = moc
//                                            
//                                            privateMOC.performBlock {
//                                                for jsonObject in jsonArray {
//                                                    let mo = … //Managed object that matches the incoming JSON structure
//                                                    //update MO with data from the dictionary
//                                                }
//                                                do {
//                                                    try privateMOC.save()
//                                                } catch {
//                                                    fatalError("Failure to save context: \(error)")
//                                                }
//                                            }
                                        }
                                    }
                                }

                            }
                        }
                    } else {
                        
                        // Use completion handler to report unlikely situation: there is a dictionary of results, but it is empty.
                        let eString = "results count is 0 or less."
                        completionHandler(success: true, errorString: eString)
                    }
                } else {
                    
                    // Use completion handler to report no error, but no procedures returned for request, so probably first time.
                    let eString = "Existing Procedure not found."
                    completionHandler(success: true, errorString: eString)
                }
            }
        }
    }
    
    // Creating a task for the POST method would require setting request properties:
    // set the request.HTTPMethod to "POST"; set the request.HTTPBody to your var jsonData: NSData from a dictionary;
    
    // Create a task using the GET method for CloudKit Web Services
    func taskForCKGetMethod(baseURL: String, method: String, tfckgCompletionHandler: (result: AnyObject!, error: NSError?) -> Void ) -> NSURLSessionDataTask {
        
        // Create a string of parameters for RESTful request.
        let urlString: String!
        
        // Create request from URL; adjust URL depending on whether request is for Meta data or the actual Procedure; add authent.token;
        urlString = baseURL + method + Tokens.ProcedurezAPIToken
        
        var jsonQDict = NSData()
        if isMeta {
            let qDict = queryDict(CloudDictKeys.JSONProcedureRecordType, filteredBy: nil, sortedBy: nil)
            let reqDict = ["query": qDict]
            print("Request Dictionary: \(reqDict)")
            
            //jsonQDict = dictToJSONData(reqDict)!
            let dataString = String(data: jsonQDict, encoding: NSUTF8StringEncoding)
            let jsonDictString = "{query:[recordType:\"JSONProcedure\"]}"
            jsonQDict = (jsonDictString.dataUsingEncoding(NSUTF8StringEncoding))!
            print("jsonQDict: \(jsonDictString)")
            print("dataString: \(dataString)")
        }
        
        print("GET URL: \(urlString)")
        
        guard let url = NSURL(string: urlString) else {
            let eString = "urlString had an issue."
            print(eString)
            
            return self.searchTask!
        }

        let request = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = "POST"
        request.HTTPBody = jsonQDict
        
        // Create a data task with a request for shared session; pass response data to JSON parser.
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, responseMeta, downloadError) -> Void in
            
            print("Starting GET task.")
            
            // Handle download error.
            if let error = downloadError {
                let newError = NetLoader.errorForData(data, error: error)
                tfckgCompletionHandler(result: nil, error: newError)
            } else {
                print("No Error, Time to Parse Data.")
                print("Cloud Kit Data: \(data)" )
                // Parse the JSON.
                NetLoader.parseJSONWithCompletionHandler(data!, pjwCompletionHandler: tfckgCompletionHandler)
            }
        })
        
        // Starts first time, and resumes if interrupted
        task.resume()
        
        // may be unnecessary
        return task

    }
    
    // Create a task using the GET method; handle JSON response.
    func taskForGETMethod(baseURL: String, method: String, requestValues: [[String:String]], tfgCompletionHandler: (result: AnyObject!, error: NSError?) -> Void ) -> NSURLSessionDataTask {
        
        // Create a string of parameters for RESTful request.
        let urlString: String!
        
        // Create request from URL; adjust URL depending on whether request is for Meta data or the actual Procedure.
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
        // after calling a function with a completionHandler closure, it returns some data that can be used;
        // session data task with request returns the response data as NSData?, metadata? as NSURLResponse response, or an error?
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, responseMeta, downloadError) -> Void in
            
            print("Starting GET task.")
            
            // Handle download error.
            if let error = downloadError {
                let newError = NetLoader.errorForData(data, error: error)
                tfgCompletionHandler(result: nil, error: newError)
            } else {
                print("No Error, Time to Parse Data.")
                
                // Parse the JSON.
                NetLoader.parseJSONWithCompletionHandler(data!, pjwCompletionHandler: tfgCompletionHandler)
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
    
    // Determine whether to get a Procedure from Parse.com, or its meta data.
    func setParseClass() -> String {
        if isMeta {
            print("Parse Class is Meta")
            return "/"+SubPaths.Query
        } else {
            print("Parse Class is Procedure")
            return "/"+SubPaths.Lookup
        }
    }
    
    // Create an error with json data from the response.
    class func errorForData(data: NSData?, error: NSError) -> NSError {
        
        print("Handling Error")
        
        let nsError = error
        
        // Check that there is a dictionary of json data.
        do {
            if let jsonData = data {
                
                let parsedResult = try NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.AllowFragments) as? [String : AnyObject]
                
                // Check that there is a key correspoding to the error status message.
                if let errorMessage = parsedResult![Keys.ErrorStatusMessage] as? String {
                    
                    // Localize the error message.
                    let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                    
                    // Return the error details.
                    return NSError(domain: "iCloud Error", code: 1, userInfo: userInfo)
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
    
    // Get the LoadMe.json file (How To Use) data; parse the json, and save the first Procedure.
    func loadHowTo(jsonData: NSData, lhtCompletionhandler: (success: Bool, errorString: String?) -> Void) {
        print("Trying to load How to Use Procedure.")
        
        // Parse JSON data using a completion handler to return the results.
        NetLoader.parseJSONWithCompletionHandler(jsonData) { (parsedResult, error) -> Void in
            
            if let error = error {
                print("Error in Parsing with rawProcedureJSON data.")
                lhtCompletionhandler(success: false, errorString: error.localizedDescription)
            } else {
                print("Parsed JSON data successfully.")
                
                // Get the necessary data from the dictionary of JSON data, use it to create a Step, 
                // iterating through children and grandchildren.
                self.parseJSONAsDictionary(parsedResult as! NSDictionary, parent: nil, pjadCompletionhandler: { (success, errorString) -> Void in
                    if let error = errorString {
                        lhtCompletionhandler(success: false, errorString: error)
                    } else {
                        // Save the context for all the Steps of the Procedure.
                        // IMPORTANT: see about threading for Core Data on another queue, not Main;
                        do {
                            try self.sharedContext.save()
                        } catch {
                            fatalError("Failure to save context: \(error)")
                        }
                        
                        lhtCompletionhandler(success: true, errorString: nil)
                    }
                })
            }
        }

    }
    
    // Get the LoadMe.json file string from the bundle; import JSON-formatted string by converting it to data.
    func importJSON(jsonString: String, completionhandler: (success: Bool, errorString: String?) -> Void) {
        print("Importing ProcedureJSON")
        
        let rawProcedureJSON = json!.dataUsingEncoding(NSUTF8StringEncoding)
        
        // Parse the json, and save the first Procedure.
        self.loadHowTo(rawProcedureJSON!) { (success, errorString) -> Void in
            if success {
                completionhandler(success: true, errorString: nil)
            } else {
                completionhandler(success: false, errorString: errorString)
            }
        }
    }
    
    // Get the necessary data from the dictionary of JSON data, use it to create a Step,
    // iterating through children and grandchildren.
    func parseJSONAsDictionary(dict: NSDictionary, parent: Step?, pjadCompletionhandler: (success: Bool, errorString: String?) -> Void) {
        
        /* Start playing with JSON here... */
        print("Parsing a JSON Dictionary to creat a Step in a Procedure.")
        
        let dictionary = dict as! [String: AnyObject]
        
        // Ensure the necessary data is in the dictionary.
        guard let title = dictionary["title"] where (dictionary["title"] as! String).characters.count <= self.titleCount else {
            let eString = "Dictionary had no title key."
            pjadCompletionhandler(success: false, errorString: eString)
            return
        }
        
        guard let details = dictionary["details"] where (dictionary["details"]as! String).characters.count <= self.detailsCount else {
            let eString = "Dictionary had no details key."
            pjadCompletionhandler(success: false, errorString: eString)
            return
        }
        
        guard let sectionIdentifier = dictionary["sectionIdentifier"] where (dictionary["sectionIdentifier"] as! String).characters.count <= self.sectionIdentifierCount else {
            let eString = "Dictionary had no sectionIdentifier key."
            pjadCompletionhandler(success: false, errorString: eString)
            return
        }
        
        guard let position = dictionary["position"] else {
            let eString = "Dictionary had no position key."
            pjadCompletionhandler(success: false, errorString: eString)
            return
        }
        
        guard let st = dictionary["steps"] else {
            let eString = "Dictionary had no steps key."
            pjadCompletionhandler(success: false, errorString: eString)
            return
        }
        
        print("Title: \(title)")
        print("Details: \(details)")
        print("SectionIdentifier: \(sectionIdentifier)")
        print("Position: \(position)")
        print("Steps: Have an array")
        
        // IMPORTANT: see about threading for Core Data on another queue, not Main;
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            // Create a Step entity.
            let step = Step(dictionary: dictionary, context: self.sharedContext)
            
            // Use parent parameter to set parent property of the Step.
            if let p = parent {
                step.parent = p
            }
            
            // Get any children as an array of Step-related dictionaries.
            let sArray = st as! [[String: AnyObject]]
            // print("Array of Steps: \(sArray)")
            
            // Iterate through the array to create the Step entities for any children.
            for d in sArray {
                self.parseJSONAsDictionary(d, parent: step, pjadCompletionhandler: { (success, errorString) -> Void in
                    if success {
                        print("Made a Step")
                    } else {
                        print("Had an error")
                    }
                })
            }
        })
        
        // Inform function caller of success in creating all the Step entities, 
        // with related parents and children, for Procedure.
        pjadCompletionhandler(success: true, errorString: nil)
    }

    // Parse JSON data using a completion handler to return the results.
    class func parseJSONWithCompletionHandler(data: NSData, pjwCompletionHandler: CompletionHandler) {
        
        print("Parsing JSON")
        let parsingError: NSError? = nil
        
        // Parse the json data in the response result.
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
            
            print("Parsed Result: \(parsedResult)")
            
            // Check for a parsing error.
            if let error = parsingError {
                
                // Report the failure and the parsing error.
                pjwCompletionHandler(parsedResult: nil, error: error)
            } else {
                
                // Return parsed results.
                pjwCompletionHandler(parsedResult: parsedResult, error: nil)
            }
        } catch let error as NSError {
            //parsingError = error
            //parsedResult = nil
            // Report the failure and the parsing error.
            pjwCompletionHandler(parsedResult: nil, error: error)
        } catch {
            print(error)
            pjwCompletionHandler(parsedResult: nil, error: nil)
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
    
    // MARK: - CloudKit Dictionaries
    
    func lookupRecordDict(nameArray:[String]) -> [[String: AnyObject]] {
        var lrDictArray = [[String: AnyObject]]()
        var lrDict: [String: AnyObject]
        
        for n in nameArray {
            lrDict = [String: AnyObject]()
            lrDict["recordName"] = n
            lrDict["desiredKeys"] = ["steps"]
            lrDictArray.append(lrDict)
        }
        
        return lrDictArray
    }
    
    func queryDict(recordType:String, filteredBy filterBy: [AnyObject]?, sortedBy sortBy: [AnyObject]?) -> [String: AnyObject] {
        var qDict: [String: AnyObject] = ["recordType":recordType]
        
        if let sort = sortBy {
            qDict["sortBy"] = sort
        }
        
        if let filter = filterBy {
            qDict["filterBy"] = filter
        }
        
        return qDict
    }
    
    func recordFieldDict(value: String) -> [String: String] {
        return ["value":value]
    }
    
    func filterDict(comparator: String, withFieldName fieldName: String, withFieldValue fieldValue: AnyObject, withDistance distance:CLLocation?) -> [String: AnyObject] {
        var filterDict: [String: AnyObject] = ["comparator":comparator, "fieldName":fieldName, "fieldValue":fieldValue]
        
        if let dist = distance {
            filterDict["distance"] = dist
        }
        
        return filterDict
    }
    
    // ascending is a string value of "true" or "false"; default is "true"
    func sortDict(fieldName: String, withAscendingBoolString ascending: String?, withRelativeLocation relativeLocation:CLLocation?) -> [String: AnyObject] {
        var sDict: [String: AnyObject] = ["fieldName":fieldName]
        
        if let ascend = ascending {
            sDict["ascending"] = ascend
        }
        
        if let rel = relativeLocation {
            sDict["relativeLocation"] = rel
        }
        
        return sDict
    }
    
    func recordOperationDict(operationType: String, onRecord record: [String: AnyObject], withDesiredKeys desiredKeys: [String]?) -> [String: AnyObject] {
        var rOpDict: [String: AnyObject] = ["operationType":operationType, "record":record]
        
        if let dKeys = desiredKeys {
            rOpDict["desiredKeys"] = dKeys
        }
        
        return rOpDict
    }
    
    func userDict(userRecordName: String, withFirstName firstName: String?, withLastName lastName: String?, withEmailAddress emailAddress: String?) -> [String: String] {
        var uDict: [String: String] = ["userRecordName":userRecordName]
        
        if let first = firstName {
            uDict["userRecordName"] = first
        }
        
        if let last = lastName {
            uDict["lastName"] = last
        }
        
        if let email = emailAddress {
            uDict["emailAddress"] = email
        }
        
        return uDict
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
