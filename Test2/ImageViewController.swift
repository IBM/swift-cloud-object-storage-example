//
//  ImageViewController.swift
//  Test2
//
//  Created by Max Shapiro on 12/19/18.
//  Copyright © 2018 Max Shapiro. All rights reserved.
//

import Foundation
import UIKit

class ImageViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var images:[UIImage]!
    var years:[String]!
    var time: Int!
    
    @IBOutlet weak var imageCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let seconds: Int = (time/100)
        let milliseconds: Int = (time / 10) % 10
        
        self.title = "Atlantic Hurricane Seasons (\(seconds).\(milliseconds) sec)"
        
        let itemSize = UIScreen.main.bounds.width/3 - 10
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        imageCollectionView.collectionViewLayout = layout
        
        imageCollectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "urlCell", for: indexPath) as! imageCell
        cell.myImageView.image = images[indexPath.row]
        cell.myLabel.text = years[indexPath.row]
        return cell
    }
}
