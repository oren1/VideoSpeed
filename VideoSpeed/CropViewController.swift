//
//  CropViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 13/10/2024.
//

import UIKit
import CropPickerView

let minVerticalMargin = 20.0
let minHorizontalMargin = 20.0

class CropViewController: UIViewController {
   
    
    var videoAspectRatio: CGFloat = 736 / 1407
    var templateImage: UIImage  = UIImage(named: "mountain-2")!
    var videoRect: CGRect!
    var cropPickerView: CropPickerView!
    var startingRect: CGRect!
    
    override func viewDidLoad() {
        super.viewDidLoad()
            view.backgroundColor = .black

            cropPickerView.image = templateImage
            cropPickerView.backgroundColor = .blue
            cropPickerView.scrollMinimumZoomScale = 1
            cropPickerView.scrollMaximumZoomScale = 1
            cropPickerView.aspectRatio = videoAspectRatio
            cropPickerView.delegate = self
            view.addSubview(cropPickerView)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    
    func updateCropViewPickerSize()  {
        let height: Double
        let width: Double
        
        if videoAspectRatio < 1 { // portrait video
             height = view.frame.size.height - (minVerticalMargin * 2)
             width = height * videoAspectRatio
        }
        else if videoAspectRatio > 1 { // landscape video
             width = view.frame.size.width - (minHorizontalMargin * 2)
             height = width / videoAspectRatio
        }
        else { // square
             height = view.frame.size.height - (minVerticalMargin * 2)
             width = view.frame.size.width - (minHorizontalMargin * 2)
           
        }
        
        cropPickerView.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            cropPickerView.widthAnchor.constraint(equalToConstant: width),
            cropPickerView.heightAnchor.constraint(equalToConstant: height),
            cropPickerView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            cropPickerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0)

        ]
        NSLayoutConstraint.activate(constraints)
        
        for constraint in cropPickerView.constraints {
          if let firstItem = constraint.firstItem,
             let secondItem = constraint.secondItem,
                type(of: firstItem) == CropView.self,
                type(of: secondItem) == LineButton.self {
              
                  constraint.constant = 0
          }
        }

        cropPickerView.layoutIfNeeded()
        
    }
    
    func isUsingCropFeature(croppedFrame: CGRect) -> Bool {
        let pickerViewWidth = cropPickerView.frame.size.width
        let pickerViewHeight = cropPickerView.frame.size.height
        
        let widthChangePercentage = (1 - (croppedFrame.width / pickerViewWidth)) * 100
        let heightChangePercentage = (1 - (croppedFrame.height / pickerViewHeight)) * 100

        if widthChangePercentage > 2 || heightChangePercentage > 2 {
            return true
        }
        
        return false
    }

}


extension CropViewController: CropPickerViewDelegate {
    func cropPickerView(_ cropPickerView: CropPickerView, result: CropResult) {}
    
    func cropPickerView(_ cropPickerView: CropPickerView, didChange frame: CGRect) {
        print("CropViewController frame: \(frame)")
        guard frame != CGRectZero else {return}
        print("cropPickerView.frame", cropPickerView.frame)
        videoRect = frame
        Task {
            await UserDataManager.main.currentSpidAsset.updateVideoRect(videoRect)
        }
//        videoRect.origin.x = cropPickerView.frame.width - frame.origin.x - frame.width
//        videoRect.origin.y = cropPickerView.frame.height - frame.origin.y - frame.height
        print("videoRect: \(videoRect!)")
//        print("videw frame:", view.frame)
        UserDataManager.main.isUsingCropFeature = isUsingCropFeature(croppedFrame: frame)
    }
}
