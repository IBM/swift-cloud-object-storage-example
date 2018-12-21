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
    
    var images:[(String,UIImage)] = []
    var totalImages = 0
    
    var currentWorkingPath = ""
    let downloadTypes = ["URL", "COS", "COS ZIP"]
    var currentDownloadType = "URL"
    let resultsFileURL = URL(string: "file://" + NSHomeDirectory() + "/Documents/results.csv")!
    
    var time: Int = 0
    var timer = Timer()
    
    var isDownloading = false
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !isDownloading {
            clear()
            startButton.isHidden = false
            loading.isHidden = true
            progressBar.isHidden = true
            timerLabel.isHidden = true
        }
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
        
        isDownloading = true

        if currentDownloadType == downloadTypes[0] {
            getURLImages()
        } else if currentDownloadType == downloadTypes[1] {
            getCOSImages()
        } else if currentDownloadType == downloadTypes[2] {
            getCOSZip()
        }
    }
    
    private func clear() {
        images = []
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

    // Gets Images on Wikipedia
    func getURLImages() {
        let alamoGroup = DispatchGroup()
        alamoGroup.enter()
        
        self.loading.isHidden = false
        self.loading.startAnimating()
        self.progressBar.isHidden = false
        
        APICalls.getURLHTML { xpath in
            self.totalImages = xpath.count
            
            self.timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
            
            for node in xpath {
                alamoGroup.enter()
                let year = String(node.text!.prefix(56).suffix(4))
                APICalls.getImage(url: "https:"+node.text!, year: year, retry: 3, completion: { image in
                    self.images.append((year,image))
                    self.progressBar.setProgress(Float(self.images.count) / Float(self.totalImages), animated: true)
                    alamoGroup.leave()
                    if self.images.count == self.totalImages {
                        alamoGroup.leave()
                    }
                })
            }
        }
            
        // after dispatchgroup is done, execute
        alamoGroup.notify(queue: .main) {
            self.timer.invalidate()
            self.loading.isHidden = true
            self.loading.stopAnimating()
            self.progressBar.isHidden = true
            self.images.sort(by: { (first, second) -> Bool in
                first.0 < second.0
            })
            self.startButton.isEnabled = true
            self.isDownloading = false
            HandleResults.writeData(fileURL: self.resultsFileURL, time: self.time, type: self.currentDownloadType)
            self.performSegue(withIdentifier: "images", sender: self)
        
        }
    }
    
    // Gets all objects (images) in COS bucket
    func getCOSImages() {
        let alamoGroup = DispatchGroup()
        alamoGroup.enter()
        
        self.loading.isHidden = false
        self.loading.startAnimating()
        self.progressBar.isHidden = false
        
        APICalls.getAccessToken(apikey: apikey) {accessToken in
            let url = self.cosPublicEndpoint + "/" + self.cosBucket
            let headers = ["Authorization": "Bearer " + accessToken, "ibm-service-instance-id": self.ibmServiceInstanceId]
            
            APICalls.getCOSBucketObjects(url: url, headers: headers) { xpath in
                self.totalImages = xpath.count
                
                self.timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
                
                for node in xpath {
                    alamoGroup.enter()
                    let year = String(node.text!.prefix(4))
                    APICalls.getImage(url: url+"/"+node.text!, year: year, headers: headers, retry: 3, completion: { image in
                        self.images.append((year,image))
                        self.progressBar.setProgress(Float(self.images.count) / Float(self.totalImages), animated: true)
                        alamoGroup.leave()
                        if self.images.count == self.totalImages {
                            alamoGroup.leave()
                        }
                    })
                }
            }
        }
        
        // after dispatchgroup is done, execute
        alamoGroup.notify(queue: .main) {
            self.timer.invalidate()
            self.loading.isHidden = true
            self.loading.stopAnimating()
            self.progressBar.isHidden = true
            self.images.sort(by: { (first, second) -> Bool in
                first.0 < second.0
            })
            self.startButton.isEnabled = true
            self.isDownloading = false
            self.performSegue(withIdentifier: "images", sender: self)
            
        }
    }
    
    // Downloads Zip file from COS bucket and decompresses file to get Images
    func getCOSZip() {
        let alamoGroup = DispatchGroup()
        alamoGroup.enter()
        
        self.loading.isHidden = false
        self.loading.startAnimating()
        self.progressBar.isHidden = false
        
        APICalls.getAccessToken(apikey: apikey) {accessToken in
        
            let url = self.cosPublicEndpoint + "/" + self.cosZipBucket + "/Atlantic_hurricane_seasons_summary_map.zip"
            let headers = ["Authorization": "Bearer " + accessToken, "ibm-service-instance-id": self.ibmServiceInstanceId]
            
            self.timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
            
            APICalls.getCOSZip(url: url, headers: headers, downloadProgress: {progress in
                self.progressBar.setProgress(progress, animated: true)
            }, completion: { images in
                for (year,image) in images {
                    self.images.append((year,image))
                }
                alamoGroup.leave()
            })
            
        }
  
        alamoGroup.notify(queue: .main) {
            self.timer.invalidate()
            self.loading.isHidden = true
            self.loading.stopAnimating()
            self.progressBar.isHidden = true
            self.images.sort(by: { (first, second) -> Bool in
                first.0 < second.0
            })
            self.startButton.isEnabled = true
            self.isDownloading = false
            self.performSegue(withIdentifier: "images", sender: self)
        }
    }
    
}
