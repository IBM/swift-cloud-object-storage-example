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
import SwiftyPlistManager

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var urlImages:[UIImage] = []
    var years:[String] = []
    var currentWorkingPath = ""
    let alamoGroup = DispatchGroup()
    var totalImages = 0
    
    var time: Int = 0
    var timer = Timer()
    
    var apikey = ""
    var ibmServiceInstanceId = ""
    var cosPublicEndpoint = ""
    var cosBucket = ""
    var cosZipBucket = ""
    
    @IBOutlet weak var urlCollectionView: UICollectionView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    @IBOutlet weak var progressBar: UIProgressView!
    
    
    // Button for URLS
    @IBOutlet weak var urlButton: UIButton!
    @IBAction func getFromURLs() {
        clear()
        clearButton.isEnabled = false
        urlButton.isEnabled = false
        cosButton.isEnabled = false
        cosZipButton.isEnabled = false
        getURLImages()
    }
    
    // Button for COS
    @IBOutlet weak var cosButton: UIButton!
    @IBAction func getFromCOS() {
        clear()
        clearButton.isEnabled = false
        urlButton.isEnabled = false
        cosButton.isEnabled = false
        cosZipButton.isEnabled = false
        getAccessToken(isZipped: false)
        //getCOSImages2()
    }
    
    // Button for COS that is Zipped
    @IBOutlet weak var cosZipButton: UIButton!
    @IBAction func getFromCOSZip() {
        clear()
        clearButton.isEnabled = false
        urlButton.isEnabled = false
        cosButton.isEnabled = false
        cosZipButton.isEnabled = false
        getAccessToken(isZipped: true)
    }
    
    // Clear UI and Data
    @IBOutlet weak var clearButton: UIButton!
    @IBAction func clear() {
        urlImages = []
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
        progressBar.isHidden = true
        
        let itemSize = UIScreen.main.bounds.width/3 - 10
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        urlCollectionView.collectionViewLayout = layout
        
        SwiftyPlistManager.shared.start(plistNames: ["Data"], logging: true)
        
        apikey = SwiftyPlistManager.shared.fetchValue(for: "apikey", fromPlistWithName: "Data") as! String
        ibmServiceInstanceId = SwiftyPlistManager.shared.fetchValue(for: "ibmServiceInstanceId", fromPlistWithName: "Data") as! String
        cosPublicEndpoint = SwiftyPlistManager.shared.fetchValue(for: "cosPublicEndpoint", fromPlistWithName: "Data") as! String
        cosBucket = SwiftyPlistManager.shared.fetchValue(for: "cosBucket", fromPlistWithName: "Data") as! String
        cosZipBucket = SwiftyPlistManager.shared.fetchValue(for: "cosZipBucket", fromPlistWithName: "Data") as! String

    }
    
    @objc private func timerUpdate() {
        time += 1
        updateTimerUI()
    }
    
    private func updateTimerUI() {
        let seconds: Int = (time/100)
        let milliseconds: Int = time % 60
        
        timerLabel.text = "\(seconds).\(milliseconds) sec"
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
            
                self.urlCall(url: "https:"+node.text!.prefix(upTo: node.text!.lastIndex(of: "/")!).replacingOccurrences(of: "/thumb", with: ""), year: String(node.text!.prefix(56).suffix(4)), retry: 3)
            }
            
            // after dispatchgroup is done, execute
            self.alamoGroup.notify(queue: .main) {
                self.loading.isHidden = true
                self.loading.stopAnimating()
                self.progressBar.isHidden = true
                self.years.sort(by: <)
                self.timer.invalidate()
                self.urlCollectionView.reloadData()
                self.clearButton.isEnabled = true
                self.urlButton.isEnabled = true
                self.cosButton.isEnabled = true
                self.cosZipButton.isEnabled = true
            }
        }
    }
    
    // Downloads an image from Wikipedia
    func urlCall(url: String, year: String, retry: Int) {
        alamoGroup.enter()
        
        Alamofire.request(url, method: .get).responseData { response in
            print(year)
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
                self.progressBar.setProgress(Float(self.urlImages.count) / Float(self.totalImages), animated: true)
            }
            // leave after done
            self.alamoGroup.leave()
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
                
                self.cosCall(url: url+"/"+node.text!, year: String(node.text!.prefix(4)), headers: headers, retry: 3)
           
            }
            
            // after dispatchgroup is done, execute
            self.alamoGroup.notify(queue: .main) {
                self.loading.isHidden = true
                self.loading.stopAnimating()
                self.progressBar.isHidden = true
                self.years.sort(by: <)
                self.timer.invalidate()
                self.urlCollectionView.reloadData()
                self.clearButton.isEnabled = true
                self.urlButton.isEnabled = true
                self.cosButton.isEnabled = true
                self.cosZipButton.isEnabled = true
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
                self.progressBar.setProgress(Float(self.urlImages.count) / Float(self.totalImages), animated: true)
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
            self.progressBar.isHidden = true
            self.years.sort(by: <)
            self.timer.invalidate()
            self.urlCollectionView.reloadData()
            self.clearButton.isEnabled = true
            self.urlButton.isEnabled = true
            self.cosButton.isEnabled = true
            self.cosZipButton.isEnabled = true
        }
    }
}
