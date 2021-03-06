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

//protocol JSONProcedurezDelegate {
//    func errorUpdating(error: NSError)
//    func modelUpdated()
//}

class NetLoader: NSObject, NSFetchedResultsControllerDelegate {
    
    typealias CompletionHandler = (parsedResult: AnyObject!, error: NSError?) -> Void
    typealias SuccessCompHandler = (success: Bool, error: NSError?) -> Void
    
    let container: CKContainer
    let publicDB: CKDatabase
    let privateDB: CKDatabase
    
    var session: NSURLSession
    
    // may not be using
    var searchTask: NSURLSessionDataTask?
    
    var isMeta: Bool
    var isSegue: Bool = false
    var isImporting: Bool = false
    
    var metaID: String?
    var procedureID: String?
    
    var metaRecordDict: [String:String]

    var procedurezArray: [RKBCloudProcedureJSON]
    var recordArray: [CKRecord]
    //var childrenArray: [CKRecord]?
    
    var JSONRecord: CKRecord?
    var stepRecord: CKRecord?
    var parentRecord: CKRecord?
    
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
        procedurezArray = [RKBCloudProcedureJSON]()
        recordArray = [CKRecord]()
        // May not need below again;
        metaRecordDict = [String:String]()
        // Leave last, or problems
        super.init()
        // uncomment this if you need it again
        //metaRecordDict = createRecordDict()
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
    
    
    
    // MARK: - CloudKit stuff
    
    // Creates a dictionary holding record related data
    func createRecordDict() -> [String:AnyObject?] {
        return [RecordKeys.RecordName:createUniqueID(),
                CloudDictKeys.RecordTypeKey:CloudDictValues.JSONProcedureMetaRecordType,
                       ProcedureKeys.Name:"Ranges",
                       ProcedureKeys.Creator:"RKB"]
    }
    
    // Uses a time stamp to create a unique ID
    func createUniqueID() -> String {
        let timestampAsString = String(format: "%f", NSDate.timeIntervalSinceReferenceDate())
        let timestampParts = timestampAsString.componentsSeparatedByString(".")
        
        return timestampParts[0]
    }
    
    // Creates a recordID, then a record from that;
    func createCKRecord(recordDict: [String:AnyObject?]) -> CKRecord {
        // Wish to create a record with an automatically created recordID
        let record = CKRecord(recordType: recordDict[CloudDictKeys.RecordTypeKey]! as! String)
        //let recordID = CKRecordID(recordName: recordDict[RecordKeys.RecordName]!)
        //let record = CKRecord(recordType: recordDict[CloudDictKeys.RecordTypeKey]!, recordID: recordID)
        record.setObject(recordDict[CloudDictKeys.TitleKey] as! String, forKey: CloudDictKeys.TitleKey)
        record.setObject(recordDict[CloudDictKeys.DetailsKey] as! String, forKey: CloudDictKeys.DetailsKey)
        record.setObject(recordDict[CloudDictKeys.SectionIdentifierKey] as! String, forKey: CloudDictKeys.SectionIdentifierKey)
        record.setObject(recordDict[CloudDictKeys.PositionKey] as! NSNumber, forKey: CloudDictKeys.PositionKey)
        return record
    }
    
    func saveCKRecord(record: CKRecord) {
        self.publicDB.saveRecord(record, completionHandler: { (stepRecord, error) in
            if error != nil {
                print("Got an error after saving step: \(error)")
            } else {
                let stepTitle = stepRecord?["title"] as! String
                print("Created a step record: \(stepTitle)")
            }
        })
    }
    
    func fetchOneRecordByRecordID(recordID: CKRecordID, completionHandler: SuccessCompHandler) {
        self.publicDB.fetchRecordWithID(recordID) { (record, error) in
            if error == nil {
                self.stepRecord = record
                print("Fetched one step record: \(self.stepRecord!["title"])")
                completionHandler(success: true, error: nil)
            } else {
                completionHandler(success: false, error: error)
            }
        }
    }
    
    func queryOneRecord(title: String, completionHandler: SuccessCompHandler) {
        let predicate = NSPredicate(format: "title == %@", title)
        let query = CKQuery(recordType: CloudDictValues.StepRecordType, predicate: predicate)
        
        publicDB.performQuery(query, inZoneWithID: nil) { (results, error) in
            if error != nil {
                print("Got an error after fetching one Step: \(error)")
                completionHandler(success: false, error: error)
            } else {
                for p in results! {
                    self.stepRecord = p
                }
                completionHandler(success: true, error: nil)
            }
        }
    }
    
    func queryChildrenRecords(reference: CKReference, completionHandler: SuccessCompHandler) {
        let predicate = NSPredicate(format: "parent == %@", reference)
        let query = CKQuery(recordType: CloudDictValues.StepRecordType, predicate: predicate)
        
        publicDB.performQuery(query, inZoneWithID: nil) { (results, error) in
            
            self.recordArray.removeAll()
            
            if error != nil {
                print("Got an error after fetching for meta: \(error)")
                completionHandler(success: false, error: error)
            } else if let res = results {
                if res.isEmpty {
                    print("The CloudKit results array was EMPTY.")
                    completionHandler(success: false, error: nil)
                } else {
                    print("The CloudKit results array was NOT empty.")
                    self.recordArray = results!
                    completionHandler(success: true, error: nil)
                }
            }
        }
    }
    
    func loadCKProcedureIntoCoreData(topStep: CKRecord, lckpCompletionHandler: SuccessCompHandler) {
        
        let privateMOC = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        privateMOC.parentContext = self.sharedContext
        
        privateMOC.performBlockAndWait {
            
            // Get the necessary data from the CloudKit topStep; use it to create a Step,
            // iterating through children and grandchildren.
            self.fetchAllCKStepsOfProcedure(topStep, parent: nil, privMOC: privateMOC, fackCompletionHandler: { (success, error) in
                if error != nil {
                    lckpCompletionHandler(success: false, error: error)
                } else {
                    // Save the context for all the Steps of the Procedure.
                    do {
                        try privateMOC.save()
                        print("Saved privateMOC")
                        //CoreDataStackManager.sharedInstance().saveContext()
                        //NetLoader.sharedInstance().isImporting = false
                        lckpCompletionHandler(success: true, error: nil)
                    } catch {
                        fatalError("Failure to save privateMOC: \(error)")
                    }
                }
            })
        }
    }
    
    func fetchAllCKStepsOfProcedure(ckStep: CKRecord, parent: Step?, privMOC: NSManagedObjectContext, fackCompletionHandler: SuccessCompHandler) {
        let stepDict = [CloudDictKeys.TitleKey: ckStep[CloudDictKeys.TitleKey] as! String,
                        CloudDictKeys.DetailsKey: ckStep[CloudDictKeys.DetailsKey] as! String,
                        CloudDictKeys.PositionKey: ckStep[CloudDictKeys.PositionKey] as! NSNumber]
        
        let newCDStep = Step(dictionary: stepDict, context: privMOC)
        
        if let p = parent {
            print("This is not a Top Step")
            newCDStep.parent = p
        } else {
            print("This IS a Top Step")
        }
        
        let reference = CKReference(record: ckStep, action: .DeleteSelf)
        
        queryChildrenRecords(reference) { (success, error) in
            if error == nil {
                if success {
                    for res in self.recordArray {
                        self.fetchAllCKStepsOfProcedure(res, parent: newCDStep, privMOC: privMOC, fackCompletionHandler: { (success, error) -> Void in
                            if success {
                                print("Made a Step")
                                // Save the context for all the Steps of the Procedure.
                                do {
                                    try privMOC.save()
                                    print("Saved privMOC")
                                    //NetLoader.sharedInstance().isImporting = false
                                } catch {
                                    fatalError("Failure to save context: \(error)")
                                }

                                fackCompletionHandler(success: true, error: nil)
                            } else {
                                print("Had an error")
                                fackCompletionHandler(success: false, error: error)
                                return
                            }
                        })
                    }
                } else {
                    fackCompletionHandler(success: true, error: nil)
                }
            } else {
                fackCompletionHandler(success: false, error: error)
                return
            }
            
            print("End of fetchAllCKStepsOfProcedure")
            fackCompletionHandler(success: true, error: nil)
        }
    }
    
    // Used to get meta ready for on cloudkitprobably will not use it again.
//    func prepareMeta() {
//        let predicate = NSPredicate(format: "name == %@", "Ranges")
//        let query = CKQuery(recordType: CloudDictValues.JSONProcedureRecordType, predicate: predicate)
//        
//        publicDB.performQuery(query, inZoneWithID: nil) { (results, error) in
//            if error != nil {
//                print("Got an error after fetching for meta: \(error)")
//            } else {
//                for p in results! {
//                    let recordID = p.recordID
//                    print("Record ID is: \(recordID)")
//                    let pName = p.valueForKey("name")
//                    print("Record name is: \(pName)")
//                    
//                    let metaRecord = self.createCKRecord(self.metaRecordDict)
//                    let procedureID = CKReference(recordID: recordID, action: .None)
//                    metaRecord.setObject(procedureID, forKey: RecordKeys.MetaID)
//                    self.publicDB.saveRecord(metaRecord, completionHandler: { (metaProcedureRecord, error) in
//                        if error != nil {
//                            print("Got an error after saving meta: \(error)")
//                        } else {
//                            print("Created a metaRecord: \(metaProcedureRecord?.valueForKey("name"))")
//                        }
//                    })
//                }
//            }
//        }
//    }
//    
    func fetchAllProcedurez(completionHandler: (success: Bool, errorString: String?) -> Void) {
        print("Fetching all Procedurez.")
        // predicate set to true gets all
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: CloudDictValues.JSONProcedureMetaRecordType, predicate: predicate)
        
        publicDB.performQuery(query, inZoneWithID: nil) { (results, error) in
            if error != nil {
                print("Got an error after fetching: \(error)")
                completionHandler(success: false, errorString: "Error: Search failed: \(error!.localizedDescription)")
            } else {
                self.recordArray.removeAll(keepCapacity: true)
                for p in results! {
                    let pName = p.valueForKey("name")
                    self.recordArray.append(p)
                    print("Record name is: \(pName)")
                    //let procedure = p as CKRecord
                    //let jsonProcedure = RKBCloudProcedureJSON(record: procedure)
                }
                completionHandler(success: true, errorString: nil)
            }
        }
    }
    
    func fetchAProcedure(procedureID: CKReference, completionHandler: (success: Bool, errorString: String?) -> Void) {
        publicDB.fetchRecordWithID(procedureID.recordID) { (record, error) in
            if error != nil {
                print("Got an error when fetching a record by ID: \(error)")
                completionHandler(success: false, errorString: "Error: Search failed: \(error!.localizedDescription)")
            } else {
                self.JSONRecord = record
                completionHandler(success: true, errorString: nil)
            }
        }
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
            let qDict = queryDict(CloudDictValues.JSONProcedureRecordType, filteredBy: nil, sortedBy: nil)
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
    func loadJSONDataIntoCoreData(jsonData: NSData, lhtCompletionhandler: (success: Bool, errorString: String?) -> Void) {
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
                //                self.parseJSONAsDictionary(parsedResult as! NSDictionary, parent: nil, ckParent: nil, pjadCompletionhandler: { (success, errorString) -> Void in
                //                    if let error = errorString {
                //                        lhtCompletionhandler(success: false, errorString: error)
                //                    } else {
                //                        // Save the context for all the Steps of the Procedure.
                //                        // IMPORTANT: see about threading for Core Data on another queue, not Main;
                //                        do {
                //                            try self.sharedContext.save()
                //                        } catch {
                //                            fatalError("Failure to save context: \(error)")
                //                        }
                //
                //                        lhtCompletionhandler(success: true, errorString: nil)
                //                    }
                //                })
                
                //IMPORTANT: Get off the Main Queue when doing Core Data intensive stuff;
                //Consider this kind of threading:
                //                                            let jsonArray = … //JSON data to be imported into Core Data
                //                                            let moc = … //Our primary context on the main queue
                //
                //let privateMOC = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
                //privateMOC.parentContext = self.sharedContext
                
                //privateMOC.performBlock {
                    
                    // Get the necessary data from the dictionary of JSON data, use it to create a Step,
                    // iterating through children and grandchildren.
                    self.parseJSONAsDictionary(parsedResult as! NSDictionary, parent: nil, ckParent: nil, pjadCompletionhandler: { (success, errorString) -> Void in
                        if let error = errorString {
                            lhtCompletionhandler(success: false, errorString: error)
                        } else {
                            dispatch_async(dispatch_get_main_queue(), {
                                
                                // Save the context for all the Steps of the Procedure.
                                // IMPORTANT: see about threading for Core Data on another queue, not Main;
                                do {
                                    try self.sharedContext.save() //privateMOC.save()//
                                    print("Saved privateMOC")
                                } catch {
                                    fatalError("Failure to save context: \(error)")
                                }
                                
                                lhtCompletionhandler(success: true, errorString: nil)
                            })
                        }
                    })
                    //                                                do {
                    //                                                    try privateMOC.save()
                    //                                                } catch {
                    //                                                    fatalError("Failure to save context: \(error)")
                    //                                                }
                    //                                            }
               // }
            }
        }
        
    }
    
    // Get the LoadMe.json file string from the bundle; import JSON-formatted string by converting it to data.
    func importJSON(jsonString: String, completionhandler: (success: Bool, errorString: String?) -> Void) {
        print("Importing ProcedureJSON")
        
        self.isImporting = true
        
        let rawProcedureJSON = json!.dataUsingEncoding(NSUTF8StringEncoding)
        
        // Parse the json, and save the first Procedure.
        self.loadJSONDataIntoCoreData(rawProcedureJSON!) { (success, errorString) -> Void in
            if success {
                
                self.isImporting = false
                completionhandler(success: true, errorString: nil)
            } else {
                self.isImporting = false
                completionhandler(success: false, errorString: errorString)
            }
        }
    }
    
    // Get the necessary data from the dictionary of JSON data, use it to create a Step,
    // iterating through children and grandchildren.
    func parseJSONAsDictionary(dict: NSDictionary, parent: Step?, ckParent: CKRecord?, pjadCompletionhandler: (success: Bool, errorString: String?) -> Void) {
        
        /* Start playing with JSON here... */
        print("Parsing a JSON Dictionary to creat a Step in a Procedure.")
        
        var dictionary = dict as! [String: AnyObject]
        
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
        
        // NOW
        // IMPORTANT: see about threading for Core Data on another queue, not Main;
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            
            // Create a Step entity.
            let step = Step(dictionary: dictionary, context: self.sharedContext)
            
            dictionary[CloudDictKeys.RecordTypeKey] = CloudDictValues.StepRecordType
            var ckStep = self.createCKRecord(dictionary)
            
            // Use parent parameter to set parent property of the Step.
            if let p = parent {
                step.parent = p
            }
            
            if let ckp = ckParent {
                ckStep["parent"] = CKReference(record: ckp, action: .DeleteSelf)
            } else {
                ckStep["parent"] = CKReference(recordID: CKRecordID(recordName: CloudDictValues.Grandpa), action: .None)
            }
            
            // Commented out to prevent duplication in cloud kit now
//            self.publicDB.saveRecord(ckStep, completionHandler: { (stepRecord, error) in
//                if error != nil {
//                    print("Got an error after saving step: \(error)")
//                } else {
//                    ckStep = stepRecord!
//                    let stepTitle = stepRecord?["title"] as! String
//                    print("Created a step record: \(stepTitle)")
//                }
//            })
            
            // Get any children as an array of Step-related dictionaries.
            let sArray = st as! [[String: AnyObject]]
            // print("Array of Steps: \(sArray)")
            
            // Iterate through the array to create the Step entities for any children.
            for d in sArray {
                self.parseJSONAsDictionary(d, parent: step, ckParent: ckStep, pjadCompletionhandler: { (success, errorString) -> Void in
                    if success {
                        print("Made a Step")
                    } else {
                        print("Had an error")
                    }
                })
            }
        //}
        
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
