//
//  HandleResults.swift
//  Test2
//
//  Created by Max Shapiro on 12/21/18.
//  Copyright © 2018 Max Shapiro. All rights reserved.
//

import Foundation

class HandleResults {
    
    static func writeData(fileURL: URL, time: Int, type: String) {

        let seconds: Int = (time/100)
        let milliseconds: Int = (time / 10) % 10
        
        let fileManager = FileManager()
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                let file = try FileHandle(forWritingTo: fileURL)
                let fileString = "\n\(Date()),\(type),\(seconds).\(milliseconds)"
                let data = fileString.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                file.seekToEndOfFile()
                file.write(data)
                file.closeFile()
            } catch {}
        } else {
            do {
                let fileString = "Date,Type,Time\n\(Date()),\(type),\(seconds).\(milliseconds)"
                let data = fileString.data(using: String.Encoding.utf8, allowLossyConversion: false)!
                try data.write(to: fileURL, options: .atomic)
            } catch {}
        }
    }
    
    static func readData(fileURL: URL, completion: @escaping (_ results: [[String]]) -> Void) {
        
        var results: [[String]] = []
        
        do {
            let fileContents = try String(contentsOf: fileURL, encoding: String.Encoding.utf8)
            
            let lines = fileContents.split(separator: "\n")
            
            for line in lines {
                var resultComponents = line.split(separator: ",")
                results.append([String(resultComponents[0]),String(resultComponents[1]),String(resultComponents[2])])
            }
            
            completion(results)
        }
        catch {}
    }
    
    static func deleteData(fileURL: URL) {
        do {
            let fileManager = FileManager()
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(atPath: fileURL.path)
            }
        } catch {}
    }
}
