//
//  ClearColorCVCell.swift
//  VideoSpeed
//
//  Created by oren shalev on 02/05/2025.
//

import UIKit

class ClearColorCVCell: UICollectionViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = frame.width / 8
    }

}
