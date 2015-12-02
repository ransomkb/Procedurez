//
//  NetLoaderConstants.swift
//  Procedurez
//
//  Created by Ransom Barber on 10/28/15.
//  Copyright © 2015 Ransom Barber. All rights reserved.
//

import Foundation

// Convenience structures for various string properties used in NetLoader
extension NetLoader {
    struct API {
        static let ParseBaseURL: String = "https://api.parse.com/1/classes/"
        static let Procedure = "Procedure"
        static let Meta = "ProcedureMeta"
    }
    
    struct Keys {
        static let ErrorStatusMessage = "errorStatusMessage"
        
        // Keys
        static let Value = "value"
        static let Field = "field"
    }
    
    struct Values {
        // RequestValues
        static let ApplicationID = "n099noVFfXjlZsqRvh0ncOniIQPE1HVUf3XaRtam"
        static let RESTAPIKey = "lcwf2OOoMeaXCSwbXuYn7AkKn0EjdRt6EiPhNzwQ"
        
        static let ParseAppIDField = "X-Parse-Application-Id"
        static let RESTAPIField = "X-Parse-REST-API-Key"
        static let ApplicationJSON = "application/json"
        static let ContentType = "Content-Type"
        
        // URL Values for Where request
        static let Key = "key"
        static let SpecificProcedure = "?where=%7B%22objectId%22%3A%22key%22%7D"
    }
    
    struct JSONResponseKeys {
        static let Results = "results"
    }
    
    struct ProcedureKeys {
        static let ObjectID = "objectId"
        static let ProcedureID = "procedureID"
        static let Name = "name"
        static let Creator = "creator"
        static let Steps = "steps"
        
        static let CreatedAt = "createdAt"
        static let UpdatedAt = "updatedAt"
    }
}