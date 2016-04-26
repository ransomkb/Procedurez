//
//  PadCellImage.swift
//  Procedurez
//
//  Created by Ransom Barber on 9/29/15.
//  Copyright © 2015 Ransom Barber. All rights reserved.
//

import Foundation

// For getting the appropriate image for the table cell backgrounds
enum PadCellImage: Int {
    // set the rawValue
    case PadRed = 0, PadOrange, PadYellow, PadGreen, PadBlue, PadPurple, PadBlack
    
    func title() -> String {
        switch self {
        case PadRed: return "PadRed"
        case PadOrange: return "PadOrange"
        case PadYellow: return "PadYellow"
        case PadGreen: return "PadGreen"
        case PadBlue: return "PadBlue"
        case PadPurple: return "PadPurple"
        case PadBlack: return "PadBlack"
        }
    }
}

