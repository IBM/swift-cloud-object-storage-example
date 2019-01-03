//
//  ResultsTableViewCell.swift
//  ImageDownloader
//
//  Created by Max Shapiro on 12/21/18.
//  Copyright © 2018 Max Shapiro. All rights reserved.
//

import UIKit

class ResultsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var time: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
