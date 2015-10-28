//
//  ProcedureCache.swift
//  Procedurez
//
//  Created by Jason on 1/31/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import UIKit

class ProcedureCache {
    
    private var inMemoryCache = NSCache()
    
    // MARK: - Retreiving images
    
    func dataWithIdentifier(identifier: String?) -> NSData? {
        
        // If the identifier is nil, or empty, return nil
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        print("Getting procedure with identifier: \(path)")
        
        // why do we need this?
        //var data: NSData?
        
        // First try the memory cache
        if let dataJson = inMemoryCache.objectForKey(path) as? NSData {
            return dataJson
        }
        
        // Next Try the hard drive
        if let data = NSData(contentsOfFile: path) {
            return data
        }
        
        return nil
    }
    
    // MARK: - Saving images
    
    func storeJson(data: NSData?, withIdentifier identifier: String) {
        
        print("Storing image")
        let path = pathForIdentifier(identifier)
        print("Stored at path: \(path)")
        
        // If the image is nil, remove images from the cache
        if data == nil {
            
            print("Removing the object at path: \(path)")
            inMemoryCache.removeObjectForKey(path)
            do {
                try NSFileManager.defaultManager().removeItemAtPath(path)
                } catch {
                    print("Caught error when removing data: \(error)")
            }
            return
        }
        
        // Otherwise, keep the image in memory
        inMemoryCache.setObject(data!, forKey: path)
        
        // And in documents directory
        //let data = UIImagePNGRepresentation(image!)
        data!.writeToFile(path, atomically: true)
    }
    
    // MARK: - Helper
    
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! //as! NSURL
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        
        return fullURL.path!
    }
}