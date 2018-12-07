//
//  Test.swift
//  Test2
//
//  Created by Max Shapiro on 10/25/18.
//  Copyright © 2018 Max Shapiro. All rights reserved.
//

import Foundation
import Alamofire
import Kanna

public class Test {
    
    static func test() {
        let url = "https://en.wikipedia.org/wiki/Atlantic_hurricane_season"
        //let parameters = ["username": "max", "password": "zzyzx"] //-d
        //let headers = ["Content-Type": "application/json"] //-H

        Alamofire.request(url, method: .get).responseJSON { response in
            print("Request: \(String(describing: response.request))")   // original url request
            print("Response: \(String(describing: response.response))") // http url response
            print("Result: \(response.result)")                         // response serialization result
            
            if let json = response.result.value {
                print("JSON: \(json)") // serialized json response
                let jsonData:Dictionary = json as! Dictionary<String, Any>
                print(jsonData["success"]!)
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)") // original server data as UTF8 string
            }
        }
    }
    
    static func getImageURLs() -> [String] {
        let url = "https://en.wikipedia.org/wiki/Atlantic_hurricane_season"
        var urls = [String]()
        Alamofire.request(url).responseString(queue: nil, encoding: .utf8) { response in
            let html = response.result.value
            let doc = try! Kanna.XML(xml: html!, encoding: .utf8)
            for node in doc.xpath("/html/body/div[3]/div[3]/div[4]/div/table/tbody/tr/td[2]/a/img/@src") {
                //print(node.text!)
                urls.append(("https:"+node.text!.prefix(upTo: node.text!.lastIndex(of: "/")!).replacingOccurrences(of: "/thumb", with: "")))
            }
            print("Here")
            print(urls)
        }
        
        return urls
    }
}
