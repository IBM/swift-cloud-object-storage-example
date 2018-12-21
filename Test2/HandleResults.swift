//
//  HandleResults.swift
//  Test2
//
//  Created by Max Shapiro on 12/21/18.
//  Copyright © 2018 Max Shapiro. All rights reserved.
//

import Foundation
import CSVImporter

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
        
        let importer = CSVImporter<[String]>(path: fileURL.path)
        importer.startImportingRecords { $0 }.onFinish { results in
            completion(results)
        }
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
