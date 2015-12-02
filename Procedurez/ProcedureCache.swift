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
    
    // MARK: - Retreiving data
    
    func dataWithIdentifier(identifier: String?) -> NSData? {
        
        // Return nil if the identifier is nil, or empty
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        // Get the full path.
        if let path = pathForBundleIdentifier(identifier!) {
            print("Getting procedure with identifier: \(path)")
            
            // Retrieve JSON data from the file.
            do {
                let jsonData = try NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe)
                print("Got the jsonData from the file.")
                
                return jsonData
            } catch {
                print("Caught error when fetching jsonData from path: \(error)")
                return nil
            }
        }
        
        return nil
    }
    
    // MARK: - Saving files
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
    // Keeping for any future need
    // Return an NSURL version.
    func pathForDocumentsIdentifier(identifier: String) -> NSURL? {
        
        // Confirm access to the Documents directory.
        if let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! { //as! NSURL
        
            // Return full path to file at identifier.
            return documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        }
        
        return nil
    }

    // Return a String of the full path.
    func pathForBundleIdentifier(identifier: String) -> String? {
        
        // Return path to JSON resource files in the bundle.
        if let path = NSBundle.mainBundle().pathForResource(identifier, ofType: "json") {
            return path
        }
        
        return nil
    }
}