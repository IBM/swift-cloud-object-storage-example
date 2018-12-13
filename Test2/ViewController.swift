//
//  ViewController.swift
//  Test2
//
//  Created by Max Shapiro on 10/25/18.
//  Copyright © 2018 Max Shapiro. All rights reserved.
//

import UIKit
import Alamofire
import Kanna
import ZIPFoundation

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var urlImages:[UIImage] = []
    var years:[String] = []
    var currentWorkingPath = ""
    let alamoGroup = DispatchGroup()
    
    let apikey = "" // Get from Max Shapiro
    let ibmServiceInstanceId = "" // Get from Max Shapiro
    
    @IBOutlet weak var urlCollectionView: UICollectionView!
    @IBOutlet weak var timer: UILabel!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    // Button for URLS
    @IBAction func getFromURLs() {
        clear()
        getURLImages()
    }
    
    // Button for COS
    @IBAction func getFromCOS() {
        clear()
        getAccessToken(isZipped: false)
        //getCOSImages2()
    }
    
    // Button for COS that is Zipped
    @IBAction func getFromCOSZip() {
        clear()
        getAccessToken(isZipped: true)
    }
    
    // Clear UI and Data
    @IBAction func clear() {
        urlImages = []
        years = []
        timer.text = "0 sec"
        
        let fileManager = FileManager()
        
        if currentWorkingPath != "" {
            do {
                try fileManager.removeItem(atPath: currentWorkingPath)
            } catch {
                print("Error removing directory")
            }
        }
        
        currentWorkingPath = ""
        
        self.urlCollectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return urlImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "urlCell", for: indexPath) as! imageCell
        cell.myImageView.image = urlImages[indexPath.row]
        cell.myLabel.text = years[indexPath.row]
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loading.isHidden = true
        
        let itemSize = UIScreen.main.bounds.width/3 - 10
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        urlCollectionView.collectionViewLayout = layout
        
    }
    
    // Gets locations of all Images on Wikipedia
    func getURLImages() {
        loading.isHidden = false
        loading.startAnimating()
        DispatchQueue.global(qos: .background).async {
            Alamofire.request("https://en.wikipedia.org/wiki/Atlantic_hurricane_season").responseString(queue: nil, encoding: .utf8) { response in
                let html = response.result.value
                let doc = try! Kanna.XML(xml: html!, encoding: .utf8)
                let urlTimeStart = NSDate()
                
                DispatchQueue.global(qos: .background).async {
                    for node in doc.xpath("/html/body/div[3]/div[3]/div[4]/div/table/tbody/tr/td[2]/a/img/@src") {
                        
                        self.urlCall(url: "https:"+node.text!.prefix(upTo: node.text!.lastIndex(of: "/")!).replacingOccurrences(of: "/thumb", with: ""), year: String(node.text!.prefix(56).suffix(4)), retry: 3)
                    }
                }
                // after dispatchgroup is done, execute
                self.alamoGroup.notify(queue: .main) {
                    self.loading.isHidden = true
                    self.loading.stopAnimating()
                    self.years.sort(by: <)
                    let urlTimeFinish = NSDate()
                    self.timer.text = String(format: "%.2f", urlTimeFinish.timeIntervalSince(urlTimeStart as Date)) + " sec"
                    self.urlCollectionView.reloadData()
                }
            }
        }
    }
    
    // Downloads an image from Wikipedia
    func urlCall(url: String, year: String, retry: Int) {
        alamoGroup.enter()
        
        Alamofire.request(url, method: .get).responseData { response in
            print(year)
            DispatchQueue.global(qos: .background).async {
                
                if let error = response.error {
                    print("Error with ",year)
                    print(error)
                    if retry > 0 {
                        self.urlCall(url: url, year: year, retry: retry - 1)
                    }
                }
                if let data = response.result.value {
                    self.urlImages.append(UIImage(data: data)!)
                    self.years.append(year)
                }
                // leave after done
                self.alamoGroup.leave()
            }
        }
    }
    
    // Gets names of all objects (images) in COS bucket
    func getCOSImages(token: String) {
        loading.isHidden = false
        loading.startAnimating()
        
        let url = "https://s3.us-east.objectstorage.softlayer.net/atlantic-hurricanes"
        let headers = ["Authorization": "Bearer " + token,
                       "ibm-service-instance-id": ibmServiceInstanceId]
        
        Alamofire.request(url, method: .get, headers: headers).responseString(queue: nil, encoding: .utf8) { response in
            let html = response.result.value
            let doc = try! Kanna.XML(xml: html!, encoding: .utf8)
            let xpath = doc.xpath("//bucket:Key", namespaces: ["bucket": "http://s3.amazonaws.com/doc/2006-03-01/"])
            let cosTimeStart = NSDate()
            
            for node in xpath {
                
                self.cosCall(url: url+"/"+node.text!, year: String(node.text!.prefix(4)), headers: headers, retry: 3)
                
            }
            
            // after dispatchgroup is done, execute
            self.alamoGroup.notify(queue: .main) {
                self.loading.isHidden = true
                self.loading.stopAnimating()
                self.years.sort(by: <)
                let cosTimeFinish = NSDate()
                self.timer.text = String(format: "%.2f", cosTimeFinish.timeIntervalSince(cosTimeStart as Date)) + " sec"
                self.urlCollectionView.reloadData()
            }
        }
    }
    
    // Downloads an image from the COS bucket
    func cosCall(url: String, year: String, headers: [String:String], retry: Int) {
        alamoGroup.enter()
        
        Alamofire.request(url, method: .get, headers: headers).responseData { response in
            print(year)
            if let error = response.error {
                print("Error with ",year)
                print(error)
                if retry > 0 {
                    self.cosCall(url: url, year: year, headers: headers, retry: retry - 1)
                }
            }
            if let data = response.result.value {
                self.urlImages.append(UIImage(data: data)!)
                self.years.append(year)
            }
            // leave after done
            self.alamoGroup.leave()
        }
    }
    
    // Gets access token needed for interacting with COS
    func getAccessToken(isZipped: Bool) {
        let url = "https://iam.bluemix.net/oidc/token"
        let parameters = ["apikey": apikey,
                          "response_type": "cloud_iam",
                          "grant_type": "urn:ibm:params:oauth:grant-type:apikey"] //-d
        let headers = ["Content-Type": "application/x-www-form-urlencoded",
                       "Accept": "application/json"] //-H
        
        Alamofire.request(url, method: .post, parameters: parameters, headers: headers).responseJSON { response in
            
            if let json = response.result.value {
                let jsonData:Dictionary = json as! Dictionary<String, Any>
                DispatchQueue.main.async {
                    if isZipped {
                        self.getCOSZip(token: jsonData["access_token"]! as! String)
                    } else {
                        self.getCOSImages(token: jsonData["access_token"]! as! String)
                    }
                }
            }
        }
    }
    
    /*func getCOSImages2() {
     var cos = COS(apiKey: apikey, ibmServiceInstanceID: ibmServiceInstanceId)
     cos.listBuckets() { result in
     print(result.buckets!.first?.bucket![0].name! as! String)
     }
     cos.listObjects(bucketName: "atlantic-hurricanes", failure: { error in
     print("Error")
     print(error)
     }) { result in
     print("result")
     print(result)
     }
     }*/
    
    // Downloads Zip file from COS bucket and decompresses file to get Images
    func getCOSZip(token: String) {
        loading.isHidden = false
        loading.startAnimating()
        
        let url = "https://s3.us-east.objectstorage.softlayer.net/atlantic-hurricanes-zip/Atlantic_hurricane_seasons_summary_map.zip"
        let headers = ["Authorization": "Bearer " + token,
                       "ibm-service-instance-id": ibmServiceInstanceId]
        
        let fileURL: URL = URL(string: "file://" + NSHomeDirectory() + "/Temp/hurricanes.zip")!
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (fileURL, [.createIntermediateDirectories, .removePreviousFile])
        }
        
        let cosTimeStart = NSDate()
        
        alamoGroup.enter()
        
        Alamofire.download(url, method: .get, headers: headers, to: destination).validate().responseData { response in
            debugPrint(response)
            
            let fileManager = FileManager()
            self.currentWorkingPath = (response.destinationURL?.deletingLastPathComponent().path)!
            
            var sourceURL = URL(fileURLWithPath: self.currentWorkingPath)
            sourceURL.appendPathComponent("hurricanes.zip")
            
            var destinationURL = URL(fileURLWithPath: self.currentWorkingPath)
            destinationURL.appendPathComponent("hurricanes")
            
            do {
                try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
                try fileManager.unzipItem(at: sourceURL, to: destinationURL)
            } catch {
                print("Extraction of ZIP archive failed with error:\(error)")
            }
            
            do {
                let destinationFiles = try fileManager.contentsOfDirectory(atPath: destinationURL.path)
                for destinationFile in destinationFiles {
                    if destinationFile.suffix(3) == "png" {
                        self.years.append(String(destinationFile.prefix(4)))
                        self.urlImages.append(UIImage(contentsOfFile: destinationURL.path + "/" + destinationFile)!)
                    }
                }
            } catch {
                print("Directory does not exist")
            }
            
            self.alamoGroup.leave()
            
        }
        self.alamoGroup.notify(queue: .main) {
            self.loading.isHidden = true
            self.loading.stopAnimating()
            self.years.sort(by: <)
            let cosTimeFinish = NSDate()
            self.timer.text = String(format: "%.2f", cosTimeFinish.timeIntervalSince(cosTimeStart as Date)) + " sec"
            self.urlCollectionView.reloadData()
        }
    }
}

