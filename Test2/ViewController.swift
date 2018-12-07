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

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var urlImages:[UIImage] = []
    var years:[String] = []
    @IBOutlet weak var urlCollectionView: UICollectionView!
    @IBOutlet weak var timer: UILabel!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    @IBAction func getFromURLs() {
        getURLImages()
    }
    
    @IBAction func getFromCOS() {
        getAccessToken()
        //getCOSImages2()
    }
    
    @IBAction func clear() {
        urlImages = []
        years = []
        self.urlCollectionView.reloadData()
        timer.text = "0 sec"
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
        // Do any additional setup after loading the view, typically from a nib.
        
       // let urls = Test.getImageURLs()
        
      //  print(urls)
        
        loading.isHidden = true
        
        let itemSize = UIScreen.main.bounds.width/3 - 10
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        urlCollectionView.collectionViewLayout = layout
        
        //getURLImages()
        
        //getAccessToken()

        }
        
    func getURLImages() {
        loading.isHidden = false
        loading.startAnimating()
        
        Alamofire.request("https://en.wikipedia.org/wiki/Atlantic_hurricane_season").responseString(queue: nil, encoding: .utf8) { response in
            let html = response.result.value
            let doc = try! Kanna.XML(xml: html!, encoding: .utf8)
            let urlTimeStart = NSDate()
            var success = false
            for node in doc.xpath("/html/body/div[3]/div[3]/div[4]/div/table/tbody/tr/td[2]/a/img/@src") {
                //print(node.text!)
                success = false
                while !success {
                    let url = URL(string: "https:"+node.text!.prefix(upTo: node.text!.lastIndex(of: "/")!).replacingOccurrences(of: "/thumb", with: ""))
                    if let data = try? Data(contentsOf: url!) {
                        self.urlImages.append(UIImage(data: data)!)
                        self.years.append(String(node.text!.prefix(56).suffix(4)))
                        success = true
                    } else {
                        print("Fail: ", node.text!.prefix(56).suffix(4))
                    }
                }
            }
            DispatchQueue.main.async {
                self.loading.isHidden = true
                self.loading.stopAnimating()
                let urlTimeFinish = NSDate()
                self.timer.text = String(format: "%.2f", urlTimeFinish.timeIntervalSince(urlTimeStart as Date)) + " sec"
                //print("Time ", urlTimeFinish.timeIntervalSince(urlTimeStart as Date))
                self.urlCollectionView.reloadData()
            }
        }
        
        
        //let url = URL(string: "https://upload.wikimedia.org/wikipedia/commons/1/14/2018_Atlantic_hurricane_season_summary_map.png")
       // let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
        //print(UIImage(data: data!))
        //image.image = UIImage(data: data!)
    }
    
    func getCOSImages(token: String) {
        loading.isHidden = false
        loading.startAnimating()
        
        let url = "https://s3.us-east.objectstorage.softlayer.net/atlantic-hurricanes"
        let headers = ["Authorization": "Bearer " + token,
                          "ibm-service-instance-id": "d12bbd09-2b1a-4cba-b7f2-7e61a66533b8"]
        
        Alamofire.request(url, method: .get, headers: headers).responseString(queue: nil, encoding: .utf8) { response in
            let html = response.result.value
            let doc = try! Kanna.XML(xml: html!, encoding: .utf8)
            let xpath = doc.xpath("//bucket:Key", namespaces: ["bucket": "http://s3.amazonaws.com/doc/2006-03-01/"])
            var current = 0
            let cosTimeStart = NSDate()
            for node in xpath {
                Alamofire.request(url+"/"+node.text!, method: .get, headers: headers).responseData { response in
                    current += 1
                    if let error = response.error {
                        print("Error with ",node.text!)
                        print(error)
                    }
                    if let data = response.result.value {
                        self.urlImages.append(UIImage(data: data)!)
                        self.years.append(String(node.text!.prefix(4)))
                    }
                    DispatchQueue.main.async {
                        if (current == xpath.count - 1) {
                            self.loading.isHidden = true
                            self.loading.stopAnimating()
                            let cosTimeFinish = NSDate()
                            self.timer.text = String(format: "%.2f", cosTimeFinish.timeIntervalSince(cosTimeStart as Date)) + " sec"
                            //print("Time ", cosTimeFinish.timeIntervalSince(cosTimeStart as Date))
                            self.urlCollectionView.reloadData()
                        }
                    }
                }
            }
        }
    }

    func getAccessToken() {
        let url = "https://iam.bluemix.net/oidc/token"
        let parameters = ["apikey": "gXwkLJrpXdHVs2PZ2HSD20PTFfV8nf1_qCk1Spzhz1Sa",
                          "response_type": "cloud_iam",
                          "grant_type": "urn:ibm:params:oauth:grant-type:apikey"] //-d
        let headers = ["Content-Type": "application/x-www-form-urlencoded",
                       "Accept": "application/json"] //-H

        Alamofire.request(url, method: .post, parameters: parameters, headers: headers).responseJSON { response in
            
            if let json = response.result.value {
                let jsonData:Dictionary = json as! Dictionary<String, Any>
                DispatchQueue.main.async {
                    self.getCOSImages(token: jsonData["access_token"]! as! String)
                }
            }
        }
    }
    
    func getCOSImages2() {
        var cos = COS(apiKey: "gXwkLJrpXdHVs2PZ2HSD20PTFfV8nf1_qCk1Spzhz1Sa", ibmServiceInstanceID: "d12bbd09-2b1a-4cba-b7f2-7e61a66533b8")
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
    }
    

}

