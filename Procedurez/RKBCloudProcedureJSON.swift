//
//  RKBCloudProcedureJSON.swift
//  Procedurez
//
//  Created by Ransom Barber on 4/28/16.
//  Copyright © 2016 Ransom Barber. All rights reserved.
//
import Foundation
import CloudKit
import UIKit

// Object holder for ProdecureMetadata from Parse.com
class RKBCloudProcedureJSON {
    
    let recordID: String!
    let name: String!
    let creator: String!
    
    var steps: String?
    
    init(record: CKRecord) {
        self.recordID = record.valueForKey("Record Name") as! String
        self.name = record.valueForKey("name") as! String
        self.creator = record.valueForKey("creator") as! String
        self.steps = nil
    }
}
