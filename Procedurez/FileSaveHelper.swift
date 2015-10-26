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
        
        createDirectory()
        
        print(self.directoryPath)
    }
    
    private func createDirectory() {
        if !directoryExists {
            do {
                try fileManager.createDirectoryAtPath(filePath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("An error was generated while creating directory.")
            }
        }
    }
    
    func saveFile(string fileContents: String) throws {
        do {
            try fileContents.writeToFile(fullyQualifiedPath, atomically: true, encoding: NSUTF8StringEncoding)
        } catch {
            throw error
        }
    }
    
    func saveFile(dataForJson dataForJson: AnyObject) throws {
        print("At saveFile now.")
        do {
            let jsonData = try convertObjectToData(dataForJson);
            if !fileManager.createFileAtPath(fullyQualifiedPath, contents: jsonData, attributes: nil) {
                throw FileErrors.FileNotSaved
            }
        } catch {
            print(error)
            throw FileErrors.FileNotSaved
        }
    }
    
    private func convertObjectToData(data: AnyObject) throws -> NSData {
        print("At convertObjectToData now")
        do {
            let newData = try NSJSONSerialization.dataWithJSONObject(data, options: .PrettyPrinted)
            return newData
        } catch {
            print("Error writing data: \(error)")
        }
        
        throw FileErrors.JsonNotSerialized
    }
    
}
