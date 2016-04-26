//
//  PhoneCellImage.swift
//  Procedurez
//
//  Created by Ransom Barber on 9/29/15.
//  Copyright © 2015 Ransom Barber. All rights reserved.
//

import Foundation

// For getting the appropriate image for the table cell backgrounds
enum PhoneCellImage: Int {
    // set the rawValue
    case PhoneRed = 0, PhoneOrange, PhoneYellow, PhoneGreen, PhoneBlue, PhonePurple, PhoneBlack
    
    func title() -> String {
        switch self {
        case PhoneRed: return "PhoneRed"
        case PhoneOrange: return "PhoneOrange"
        case PhoneYellow: return "PhoneYellow"
        case PhoneGreen: return "PhoneGreen"
        case PhoneBlue: return "PhoneBlue"
        case PhonePurple: return "PhonePurple"
        case PhoneBlack: return "PhoneBlack"
        }
    }
}
