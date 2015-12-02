//
//  ParseProcedure.swift
//  Procedurez
//
//  Created by Ransom Barber on 11/9/15.
//  Copyright © 2015 Ransom Barber. All rights reserved.
//

import Foundation
import UIKit

// Object holder for ProdecureMetadata from Parse.com
class ParseProcedure {
    
    let objectId: String!
    let name: String!
    let creator: String!
    var procedureId: String!
    
    var steps: String?
    
    init(dictionary: [String : AnyObject]) {
        self.objectId = dictionary["objectId"] as! String
        self.name = dictionary["name"] as! String
        self.creator = dictionary["creator"] as! String
        self.procedureId = dictionary["procedureID"] as! String
        self.steps = nil
    }
}