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
        
        if let path = pathForBundleIdentifier(identifier!) {
            print("Getting procedure with identifier: \(path)")
            
            do {
                let jsonData = try NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe)
                print("Got the jsonData from the file.")
                
                return jsonData
            } catch {
                print("Caught error when fetching jsonData from path: \(error)")
                return nil
            }
        
        // First try the memory cache
//        if let dataJson = inMemoryCache.objectForKey(path) as? NSData {
//            print("Found the data in the cache.")
//            return dataJson
//        }
        
        // Next Try the hard drive
//        if let data = NSData(contentsOfFile: path) {
//            print("Found the data on the hard drive.")
//            return data
//        }
            
        }
        
        return nil
    }
    
    // MARK: - Saving images
    // Not Using; keeping for future updates to JSON File.
    func storeJson(data: NSData?, withIdentifier identifier: String) {
        
        print("Storing image")
        let path = pathForBundleIdentifier(identifier)
        print("Stored at path: \(path)")
        
        // If the image is nil, remove images from the cache
        if data == nil {
            
            print("Removing the object at path: \(path)")
            inMemoryCache.removeObjectForKey(path!)
            do {
                // Maybe change this to nsbundle
                try NSFileManager.defaultManager().removeItemAtPath(path!)
                } catch {
                    print("Caught error when removing data: \(error)")
            }
            return
        }
        
        // Otherwise, keep the image in memory
        inMemoryCache.setObject(data!, forKey: path!)
        
        // And in documents directory
        //let data = UIImagePNGRepresentation(image!)
        data!.writeToFile(path!, atomically: true)
    }
    
    // MARK: - Helper
    
    func pathForDocumentsIdentifier(identifier: String) -> NSURL? {
        if let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! { //as! NSURL
        
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        
         // Return path to JSON resource files in the bundle.
//        if let path = NSBundle.mainBundle().pathForResource(identifier, ofType: "json") {
//            return path
//        }
            return fullURL
        }
        
        return nil
    }

    
    func pathForBundleIdentifier(identifier: String) -> String? {
//        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! //as! NSURL
//        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        
        // Return path to JSON resource files in the bundle.
        if let path = NSBundle.mainBundle().pathForResource(identifier, ofType: "json") {
            return path
        }
        
        return nil
    }
}