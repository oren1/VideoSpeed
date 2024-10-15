//
//  CropViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 13/10/2024.
//

import UIKit
import CropPickerView

class CropViewController: UIViewController {
   
    var minVerticalMargin = 20.0
    var minHorizontalMargin = 20.0
    var videoAspectRatio: CGFloat = 736 / 1407
    var templateImage: UIImage  = UIImage(named: "mountain-2")!
    var videoRect: CGRect!
    var cropPickerView: CropPickerView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        cropPickerView = CropPickerView()
        cropPickerView.image = templateImage
        cropPickerView.aspectRatio = videoAspectRatio
        cropPickerView.delegate = self

        view.addSubview(cropPickerView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }

    
    
    func updateCropViewPickerSize()  {
        if videoAspectRatio > 0.50 { // portrait video
            let height = view.frame.size.height - (minVerticalMargin * 2)
            let width = height * videoAspectRatio
            cropPickerView.frame = CGRect(x: 0, y: minVerticalMargin, width: width, height: height)
            cropPickerView.translatesAutoresizingMaskIntoConstraints = false
            let constraints = [
                cropPickerView.widthAnchor.constraint(equalToConstant: width),
                cropPickerView.heightAnchor.constraint(equalToConstant: height),
                cropPickerView.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
                cropPickerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0)

            ]
            NSLayoutConstraint.activate(constraints)
            print("cropPickerView.frame", cropPickerView.frame)
            
        }
        else if videoAspectRatio < 0.50 { // landscape video
            let width = view.frame.size.width - (minHorizontalMargin * 2)
            let height = width / videoAspectRatio
            cropPickerView.frame = CGRect(x: minHorizontalMargin, y: 0, width: width, height: height)
            cropPickerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
        else { // square
            let height = view.frame.size.height - (minVerticalMargin * 2)
            let width = view.frame.size.width - (minHorizontalMargin * 2)
            cropPickerView.frame = CGRect(x: minHorizontalMargin, y: minVerticalMargin, width: width, height: height)
            cropPickerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }
    
}


extension CropViewController: CropPickerViewDelegate {
    func cropPickerView(_ cropPickerView: CropPickerView, result: CropResult) {}
    
    func cropPickerView(_ cropPickerView: CropPickerView, didChange frame: CGRect) {
        print("frame: \(frame)")
        videoRect = frame
        videoRect.origin.y = cropPickerView.frame.height - frame.origin.y - frame.height
    }
}
