//
//  ColorCollectionViewCell.swift
//  VideoSpeed
//
//  Created by oren shalev on 01/05/2025.
//

import UIKit




class ColorCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var colorView: UIView!
   
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = frame.width / 8
        colorView.layer.cornerRadius = colorView.frame.width / 20
    }

}
