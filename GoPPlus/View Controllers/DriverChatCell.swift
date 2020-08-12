//
//  DriverChatCell.swift
//  GoPPlus
//
//  Created by Cristina on 12/19/18.
//  Copyright © 2018 GFA. All rights reserved.
//

import UIKit

class DriverChatCell: UITableViewCell {
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var date: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
