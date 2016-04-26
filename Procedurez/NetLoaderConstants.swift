//
//  NetLoaderConstants.swift
//  Procedurez
//
//  Created by Ransom Barber on 10/28/15.
//  Copyright © 2015 Ransom Barber. All rights reserved.
//

import Foundation

// Convenience structures for various string properties used in NetLoader
extension NetLoader
{
    
    // POST [path]/database/[version]/[container]/[environment]/[database]/[subpath]
    
    struct API {
        static let Path = "https://api.apple-cloudkit.com"
        static let Version = "1"
        static let Container = "iCloud.com.hart-book.Procedurez"
        static let EnvironmentDevelopment = "development"
        static let EnvironmentProduction = "production"
        static let PublicDatabase = "public"
        static let PrivateDatabase = "private"
        
        static let ParseBaseURL: String = "https://api.parse.com/1/classes/"
        static let Procedure = "Procedure"
        static let Meta = "ProcedureMeta"
    }
    
    struct Tokens {
        static let ProcedurezAPIToken = "?ckAPIToken=c2355c68a81739fb91cb1a5df6d3a7a07f85d355853217b9f7c55770d66a29ac"
        static let WebAuthToken = "&ckWebAuthToken="
    }
    
    struct SubPaths {
        static let Records = "records"
        static let Assets = "assets"
        static let Zones = "zones"
        static let Users = "users"
        static let Tokens = "tokens"
        static let Subscriptions = "subscriptions"
        
        static let ID = "id"
        static let Create = "create"
        static let Modify = "modify"
        static let Query = "query"
        static let Lookup = "lookup"
        static let Changes = "changes"
        static let Upload = "upload"
        
        static let List = "list"
        static let Email = "email"
        static let Current = "current"
        static let Rereference = "rereference"
        static let Register = "register"
        static let Contacts = "contacts"
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
    
    struct OperationTypes {
        static let CreateType = "create"
        static let UpdateType = "update"
        static let ForceUpdateType = "forceUpdate"
        static let ReplaceType = "replace"
        static let ForceReplaceType = "forceReplace"
        static let DeleteType = "delete"
        static let ForceDeleteType = "forceDelete"
    }
    
    // Probably just used in responses
    struct CKValues {
        static let AssetType = "Asset"
        static let BytesType = "Bytes"
        static let DateTimeType = "Date/Time"
        static let DoubleType = "Double"
        static let Int64Type = "Int(64)"
        static let LocationType = "Location"
        static let ReferenceType = "Reference"
        static let StringType = "String"
        static let ListType = "List"
    }
    
    struct Comparators {
        static let EQUALS = "EQUALS"
        static let BEGINSWITH = "BEGINS_WITH"
    }
    
}