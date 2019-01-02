//
//  APICalls.swift
//  Test2
//
//  Created by Max Shapiro on 12/20/18.
//  Copyright © 2018 Max Shapiro. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import Kanna

class APICalls {
    
    // Downloads an image
    static func getImage(url: String, year: String, headers: [String:String]? = nil, retry: Int, completion: @escaping (_ image: UIImage) -> Void) {
        Alamofire.request(url, method: .get, headers: headers).responseData { response in
            //print(year) //Used for debugging
            
            if let _ = response.error {
                if retry > 0 {
                    getImage(url: url, year: year, retry: retry - 1, completion: completion)
                }
            }
            
            if let data = response.result.value {
                if let image = UIImage(data: data) {
                    completion(image)
                }
            }
        }
    }
    
    // Gets locations of all Images on Wikipedia
    static func getURLHTML(completion: @escaping (_ html: XPathObject) -> Void) {
        Alamofire.request("https://en.wikipedia.org/wiki/Atlantic_hurricane_season").responseString(queue: nil, encoding: .utf8) { response in
            let html = response.result.value
            let doc = try! Kanna.XML(xml: html!, encoding: .utf8)
            
            let xpath = doc.xpath("/html/body/div[3]/div[3]/div[4]/div/table/tbody/tr/td[2]/a/img/@src")
            
            completion(xpath)
        }
    }
    
    // Get a list of Objects in a COS Bucket
    static func getCOSBucketObjects(url: String, headers: [String:String], completion: @escaping (_ html: XPathObject) -> Void) {
        Alamofire.request(url, method: .get, headers: headers).responseString(queue: nil, encoding: .utf8) { response in
            let html = response.result.value
            let doc = try! Kanna.XML(xml: html!, encoding: .utf8)
            
            let xpath = doc.xpath("//bucket:Key", namespaces: ["bucket": "http://s3.amazonaws.com/doc/2006-03-01/"])
            
            completion(xpath)
        }
    }
    
    // Gets access token needed for interacting with COS
    static func getAccessToken(apikey: String, completion: @escaping (_ accessToken: String) -> Void) {
        let url = "https://iam.bluemix.net/oidc/token"
        let parameters = ["apikey": apikey,
                          "response_type": "cloud_iam",
                          "grant_type": "urn:ibm:params:oauth:grant-type:apikey"] //-d
        let headers = ["Content-Type": "application/x-www-form-urlencoded",
                       "Accept": "application/json"] //-H
        
        Alamofire.request(url, method: .post, parameters: parameters, headers: headers).responseJSON { response in
            if let json = response.result.value {
                if let jsonData:Dictionary = json as? Dictionary<String, Any> {
                    if let accessToken = jsonData["access_token"] as? String {
                        completion(accessToken)
                    }
                }
            }
        }
    }
    
    // Downloads Zip file from COS bucket and decompresses file to get Images
    static func getCOSZip(url: String, headers: [String:String], downloadProgress: @escaping (_ progress: Float) -> Void, completion: @escaping (_ images: [String:UIImage]) -> Void) {
        let fileURL: URL = URL(string: "file://" + NSHomeDirectory() + "/Documents/HurricaneData/hurricanes.zip")!
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (fileURL, [.createIntermediateDirectories, .removePreviousFile])
        }
        
        do {
            let fileManagerCheck = FileManager()
            if fileManagerCheck.fileExists(atPath: fileURL.deletingLastPathComponent().path) {
                try fileManagerCheck.removeItem(atPath: fileURL.deletingLastPathComponent().path)
            }
        } catch {}
        
        Alamofire.download(url, method: .get, headers: headers, to: destination)
            .downloadProgress(closure: { progress in
                downloadProgress(Float(progress.fractionCompleted))
                
            }).validate().responseData { response in
                let fileManager = FileManager()
                let currentWorkingPath = (response.destinationURL?.deletingLastPathComponent().path)!
                
                var sourceURL = URL(fileURLWithPath: currentWorkingPath)
                sourceURL.appendPathComponent("hurricanes.zip")
                
                var destinationURL = URL(fileURLWithPath: currentWorkingPath)
                destinationURL.appendPathComponent("hurricanes")
                
                do {
                    try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
                    try fileManager.unzipItem(at: sourceURL, to: destinationURL)
                    
                    let destinationFiles = try fileManager.contentsOfDirectory(atPath: destinationURL.path)
                    
                    var images: [String:UIImage] = [:]
                    
                    for destinationFile in destinationFiles {
                        if destinationFile.suffix(3) == "png" {
                            images[String(destinationFile.prefix(4))] = UIImage(contentsOfFile: destinationURL.path + "/" + destinationFile)
                        }
                    }
                    
                    completion(images)
                    
                } catch {
                    print("Extraction of ZIP archive failed with error:\(error)")
                }
        }
    }

}
