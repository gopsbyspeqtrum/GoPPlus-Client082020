//
//  VehicleCell.swift
//  GoPPlus
//
//  Created by Cristina Martinez on 11/10/18.
//  Copyright © 2018 GFA. All rights reserved.
//

import UIKit

class VehicleCell: UICollectionViewCell {
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var minprice: UILabel!
    @IBOutlet weak var minuteprice: UILabel!
    @IBOutlet weak var kmprice: UILabel!
    @IBOutlet weak var typeName: UILabel!
    
    var selectedImage:String = ""
    var unselectedImage:String = ""

    func setImage(selected:Bool) {
        
        if selectedImage.isEmpty {
            return
        }
        
        if unselectedImage.isEmpty {
            return
        }
        
        var url = URL(string:  Constants.APIEndpoint.admin + "images/Uploads/" + selectedImage)
        
        if !selected {
            url = URL(string: Constants.APIEndpoint.admin + "images/Uploads/" + unselectedImage)
        }
        
        if (url != nil) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url!) {
                    DispatchQueue.main.async {
                        self.image.image = UIImage(data: data)
                    }
                } else {
                    DispatchQueue.main.async {
                        if (selected) {
                            self.image.image = UIImage(named: "vehiclered")
                        } else {
                            self.image.image = UIImage(named: "vehicle")
                        }
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                if (selected) {
                    self.image.image = UIImage(named: "vehiclered")
                } else {
                    self.image.image = UIImage(named: "vehicle")
                }
            }
        }
    }
}
