//
//  CustomViewCell.swift
//  faceRecognition
//
//  Created by Evridiki Christodoulou on 03/04/2018.
//  Copyright © 2018 Evridiki Christodoulou. All rights reserved.
//

import UIKit

class CustomViewCell: UITableViewCell {
    
    @IBOutlet weak var cellImage: UIImageView!
    
    @IBOutlet weak var cellView: UIView!
    
    @IBOutlet weak var cellLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
