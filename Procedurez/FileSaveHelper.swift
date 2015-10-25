//
//  FileSaveHelper.swift
//  Procedurez
//
//  Created by Ransom Barber on 10/25/15.
//  Copyright © 2015 Ransom Barber. All rights reserved.
//

import Foundation

class FileSaveHelper {
    // MARK: - Error Types
    private enum FileErrors:ErrorType {
        case JsonNotSerialized
        case FileNotSaved
    }
    
    // MARK: - File Extension Types
    enum FileExtension: String {
        case TXT = ".txt"
        case JPG = ".jpg"
        case JSON = ".json"
    }
    
    // MARK: - Private Properties
    private let directory: NSSearchPathDirectory
    private let directoryPath: String
    private let fileManager = NSFileManager.defaultManager()
    private let fileName: String
    private let filePath:String
    private let fullyQualifiedPath: String
    private let subDirectory: String
    
    var fileExists: Bool {
        get {
            return fileManager.fileExistsAtPath(fullyQualifiedPath)
        }
    }
    
    var directoryExists: Bool {
        get {
            var isDir = ObjCBool(true)
            return fileManager.fileExistsAtPath(filePath, isDirectory: &isDir)
        }
    }
    
    init(fileName: String, fileExtension: FileExtension, subDirectory: String, directory: NSSearchPathDirectory) {
        self.fileName = fileName + fileExtension.rawValue
        self.subDirectory = "/\(subDirectory)"
        self.directory = directory
        
        self.directoryPath = NSSearchPathForDirectoriesInDomains(directory, .UserDomainMask, true)[0]
        self.filePath = directoryPath + self.subDirectory
        self.fullyQualifiedPath = "\(filePath)/\(self.fileName)"
        
        print(self.directoryPath)
    }
    
}
