//
//  RKBCloudProcedureJSON.swift
//  Procedurez
//
//  Created by Ransom Barber on 4/28/16.
//  Copyright © 2016 Ransom Barber. All rights reserved.
//
import Foundation
import UIKit

// Object holder for ProdecureMetadata from Parse.com
class RKBCloudProcedureJSON {
    
    let objectId: String!
    let name: String!
    let creator: String!
    var procedureId: String!
    
    var steps: String?
    
    init(dictionary: [String : AnyObject]) {
        self.objectId = dictionary["Record Name"] as! String
        self.name = dictionary["name"] as! String
        self.creator = dictionary["creator"] as! String
        self.procedureId = dictionary["procedureID"] as! String
        self.steps = nil
    }
}
