//
//  PhotoCell.swift
//  VideoSpeed
//
//  Created by oren shalev on 14/07/2023.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var indicatorView: UIView!
    
    func showIndicatorView(orderNumber: Int) {
        indicatorView.isHidden = false
        numberLabel.text = "\(orderNumber)"
    }
    
    func hideIndicatorView() {
        indicatorView.isHidden = true
    }
}
