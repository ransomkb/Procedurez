//
//  StepChildSection.swift
//  Procedurez
//
//  Created by Ransom Barber on 9/29/15.
//  Copyright © 2015 Ransom Barber. All rights reserved.
//

import Foundation

enum StepChildSection: String {
    case ToDo = "10"
    case Done = "20"
    
    func title() -> String {
        switch self {
        case ToDo: return "To Do"
        case Done: return "Done"
        }
    }
}