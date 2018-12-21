//
//  ResultsViewController.swift
//  Test2
//
//  Created by Max Shapiro on 12/21/18.
//  Copyright © 2018 Max Shapiro. All rights reserved.
//

import Foundation
import UIKit

class ResultsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let resultsFileURL = URL(string: "file://" + NSHomeDirectory() + "/Documents/results.csv")!
    
    @IBOutlet weak var tableView: UITableView!
    
    var resultData: [[String]] = []
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        HandleResults.readData(fileURL: resultsFileURL) { results in
            self.resultData = results
            self.resultData.removeFirst()
            
            self.tableView.reloadData()
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "resultsCell", for: indexPath) as! ResultsTableViewCell
        
        cell.date.text = String(resultData[indexPath.row][0].split(separator: " ")[0])
        cell.type.text = resultData[indexPath.row][1]
        cell.time.text = resultData[indexPath.row][2]
        
        return (cell)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultData.count
    }
    
    @IBAction func clear(_ sender: Any) {
        HandleResults.deleteData(fileURL: resultsFileURL)
        resultData = []
        tableView.reloadData()
    }
}
