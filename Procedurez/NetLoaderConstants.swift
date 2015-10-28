//
//  NetLoaderConstants.swift
//  Procedurez
//
//  Created by Ransom Barber on 10/28/15.
//  Copyright © 2015 Ransom Barber. All rights reserved.
//

import Foundation

extension NetLoader {
    struct API {
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME = "flickr.photos.search"
    }
    
    struct Keys {
        static let Title = "title"
        static let ErrorStatusMessage = "errorStatusMessage"
    }
}