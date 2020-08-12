//
//  CardCell.swift
//  GoPPlus
//
//  Created by Cristina on 12/9/18.
//  Copyright © 2018 GFA. All rights reserved.
//

import UIKit

class CardCell: UITableViewCell {
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    var actionBlock: (() -> Void)? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func deleteCard(_ sender: Any) {
        actionBlock?()
    }
}
