//
//  HistoryCell.swift
//  GoPPlus
//
//  Created by Cristina Martinez on 11/10/18.
//  Copyright © 2018 GFA. All rights reserved.
//

import UIKit

class HistoryCell: UITableViewCell {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var mapImage: UIImageView!
    @IBOutlet weak var driverLabel: UILabel!
    @IBOutlet weak var carLabel: UILabel!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var stopLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    
    

}
