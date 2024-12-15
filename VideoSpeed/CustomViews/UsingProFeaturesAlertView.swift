//
//  UsingProFeaturesAlertView.swift
//  VideoSpeed
//
//  Created by oren shalev on 18/08/2023.
//

import UIKit
import AVFoundation
import FirebaseRemoteConfig

class UsingProFeaturesAlertView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var continueButton: UIButton!
    var onCancel: VoidClosure?
    var onContinue: VoidClosure?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    @IBOutlet weak var mp4View: UIView!
    @IBOutlet weak var fpsView: UIView!
    @IBOutlet weak var soundOffView: UIView!
    @IBOutlet weak var sliderPrecisionView: UIView!
    
    @IBOutlet weak var cropView: UIView!
    @IBOutlet weak var sliderPrecisionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var soundOffViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var fpsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoFormatViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cropViewHeightConstraint: NSLayoutConstraint!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("UsingProFeaturesAlertView", owner: self)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.layer.cornerRadius = 8
        continueButton.layer.cornerRadius = 8
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func updateStatus(usingSlider: Bool, soundOn: Bool, fps: Int32, fileType: AVFileType, usingCropFeature: Bool) {
        
        let isCropFeatureFree = RemoteConfig.remoteConfig().configValue(forKey: "crop_feature_free").numberValue.boolValue

        sliderPrecisionViewHeightConstraint.constant = 0
        sliderPrecisionView.isHidden = true
        
        soundOffViewHeightConstraint.constant = 0
        soundOffView.isHidden = true
        
        fpsViewHeightConstraint.constant = 0
        fpsView.isHidden = true
        
        videoFormatViewHeightConstraint.constant = 0
        mp4View.isHidden = true

        cropViewHeightConstraint.constant = 0
        cropView.isHidden = true
        
        if usingSlider {
            sliderPrecisionViewHeightConstraint.constant = 24
            sliderPrecisionView.isHidden = false
        }
        if !soundOn {
            soundOffViewHeightConstraint.constant = 24
            soundOffView.isHidden = false
        }
        if fps != 30 {
            fpsViewHeightConstraint.constant = 24
            fpsView.isHidden = false
        }
        if fileType == .mp4 {
            videoFormatViewHeightConstraint.constant = 24
            mp4View.isHidden = false
        }
        if usingCropFeature && !isCropFeatureFree {
            cropViewHeightConstraint.constant = 24
            cropView.isHidden = false
        }
        
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        onCancel?()
    }
    
    @IBAction func continueButtonTapped(_ sender: Any) {
        onContinue?()
    }
    
}
