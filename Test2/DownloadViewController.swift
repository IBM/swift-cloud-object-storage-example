//
//  DownloadViewController.swift
//  Test2
//
//  Created by Max Shapiro on 12/19/18.
//  Copyright © 2018 Max Shapiro. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import Kanna
import ZIPFoundation
import SwiftyPlistManager

class DownloadViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var images:[UIImage] = []
    var years:[String] = []
    var currentWorkingPath = ""
    let alamoGroup = DispatchGroup()
    var totalImages = 0
    let downloadTypes = ["URL", "COS", "COS ZIP"]
    var currentDownloadType = "URL"
    
    var time: Int = 0
    var timer = Timer()
    
    var apikey = ""
    var ibmServiceInstanceId = ""
    var cosPublicEndpoint = ""
    var cosBucket = ""
    var cosZipBucket = ""
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var downloadPickerView: UIPickerView!
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
        //return UIStatusBarStyle.default   // Make dark again
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clear()
        
        startButton.isHidden = false
        loading.isHidden = true
        progressBar.isHidden = true
        timerLabel.isHidden = true
        
        SwiftyPlistManager.shared.start(plistNames: ["Data"], logging: false)
        
        apikey = SwiftyPlistManager.shared.fetchValue(for: "apikey", fromPlistWithName: "Data") as! String
        ibmServiceInstanceId = SwiftyPlistManager.shared.fetchValue(for: "ibmServiceInstanceId", fromPlistWithName: "Data") as! String
        cosPublicEndpoint = SwiftyPlistManager.shared.fetchValue(for: "cosPublicEndpoint", fromPlistWithName: "Data") as! String
        cosBucket = SwiftyPlistManager.shared.fetchValue(for: "cosBucket", fromPlistWithName: "Data") as! String
        cosZipBucket = SwiftyPlistManager.shared.fetchValue(for: "cosZipBucket", fromPlistWithName: "Data") as! String
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let imageViewController = segue.destination as? ImageViewController {
            imageViewController.images = images
            imageViewController.years = years
            imageViewController.time = time
        }
    }
    
    @objc private func timerUpdate() {
        time += 1
        updateTimerUI()
    }
    
    private func updateTimerUI() {
        let seconds: Int = (time/100)
        let milliseconds: Int = (time / 10) % 10
        
        timerLabel.text = "\(seconds).\(milliseconds) sec"
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return downloadTypes[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return downloadTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currentDownloadType = downloadTypes[row]
    }
    
    //Starts download of images
    @IBAction func startDownload(_ sender: Any) {
        clear()
        startButton.isEnabled = false
        startButton.isHidden = true
        timerLabel.isHidden = false

        if currentDownloadType == downloadTypes[0] {
            getURLImages()
        } else if currentDownloadType == downloadTypes[1] {
            getAccessToken(isZipped: false)
        } else if currentDownloadType == downloadTypes[2] {
            getAccessToken(isZipped: true)
        }
    }
    
    private func clear() {
        images = []
        years = []
        totalImages = 0
        progressBar.setProgress(0.0, animated: false)
        timer.invalidate()
        time = 0
        updateTimerUI()
        
        let fileManager = FileManager()
        
        if currentWorkingPath != "" {
            do {
                try fileManager.removeItem(atPath: currentWorkingPath)
            } catch {
                print("Error removing directory")
            }
        }
        
        currentWorkingPath = ""
    }

    // Gets locations of all Images on Wikipedia
    func getURLImages() {
        loading.isHidden = false
        loading.startAnimating()
        
        Alamofire.request("https://en.wikipedia.org/wiki/Atlantic_hurricane_season").responseString(queue: nil, encoding: .utf8) { response in
            let html = response.result.value
            let doc = try! Kanna.XML(xml: html!, encoding: .utf8)
            
            let xpath = doc.xpath("/html/body/div[3]/div[3]/div[4]/div/table/tbody/tr/td[2]/a/img/@src")
            
            self.totalImages = xpath.count
            self.progressBar.isHidden = false
            
            self.timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
            
            for node in xpath {
                
                self.getImage(url: "https:"+node.text!.prefix(upTo: node.text!.lastIndex(of: "/")!).replacingOccurrences(of: "/thumb", with: ""), year: String(node.text!.prefix(56).suffix(4)), retry: 3)
            }
            
            // after dispatchgroup is done, execute
            self.alamoGroup.notify(queue: .main) {
                self.loading.isHidden = true
                self.loading.stopAnimating()
                self.progressBar.isHidden = true
                self.years.sort(by: <)
                self.timer.invalidate()
                self.startButton.isEnabled = true
                //self.urlCollectionView.reloadData()
                self.performSegue(withIdentifier: "images", sender: self)
            }
        }
    }
    
    // Gets names of all objects (images) in COS bucket
    func getCOSImages(token: String) {
        loading.isHidden = false
        loading.startAnimating()
        
        let url = cosPublicEndpoint + "/" + cosBucket
        let headers = ["Authorization": "Bearer " + token,
                       "ibm-service-instance-id": ibmServiceInstanceId]
        
        Alamofire.request(url, method: .get, headers: headers).responseString(queue: nil, encoding: .utf8) { response in
            let html = response.result.value
            let doc = try! Kanna.XML(xml: html!, encoding: .utf8)
            let xpath = doc.xpath("//bucket:Key", namespaces: ["bucket": "http://s3.amazonaws.com/doc/2006-03-01/"])
            
            self.totalImages = xpath.count
            self.progressBar.isHidden = false
            
            self.timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
            
            for node in xpath {
                
                self.getImage(url: url+"/"+node.text!, year: String(node.text!.prefix(4)), headers: headers, retry: 3)
                
            }
            
            // after dispatchgroup is done, execute
            self.alamoGroup.notify(queue: .main) {
                self.loading.isHidden = true
                self.loading.stopAnimating()
                self.progressBar.isHidden = true
                self.years.sort(by: <)
                self.timer.invalidate()
                //self.urlCollectionView.reloadData()
                self.startButton.isEnabled = true
            }
        }
    }
    
    // Downloads an image
    func getImage(url: String, year: String, headers: [String:String]? = nil, retry: Int) {
        alamoGroup.enter()
        
        Alamofire.request(url, method: .get, headers: headers).responseData { response in
            print(year)
            if let error = response.error {
                print("Error with ",year)
                print(error)
                if retry > 0 {
                    self.getImage(url: url, year: year, headers: headers, retry: retry - 1)
                }
            }
            if let data = response.result.value {
                self.images.append(UIImage(data: data)!)
                self.years.append(year)
                self.progressBar.setProgress(Float(self.images.count) / Float(self.totalImages), animated: true)
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
        
        let url = cosPublicEndpoint + "/" + cosZipBucket + "/Atlantic_hurricane_seasons_summary_map.zip"
        let headers = ["Authorization": "Bearer " + token,
                       "ibm-service-instance-id": ibmServiceInstanceId]
        
        let fileURL: URL = URL(string: "file://" + NSHomeDirectory() + "/Temp/hurricanes.zip")!
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (fileURL, [.createIntermediateDirectories, .removePreviousFile])
        }
        
        self.progressBar.isHidden = false
        
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: true)
        
        alamoGroup.enter()
        
        Alamofire.download(url, method: .get, headers: headers, to: destination)
            .downloadProgress(closure: { progress in
                self.progressBar.setProgress(Float(progress.fractionCompleted), animated: true)
            })
            .validate().responseData { response in
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
                            self.images.append(UIImage(contentsOfFile: destinationURL.path + "/" + destinationFile)!)
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
            self.progressBar.isHidden = true
            self.years.sort(by: <)
            self.timer.invalidate()
            //self.urlCollectionView.reloadData()
            self.startButton.isEnabled = true
        }
    }
    
}
