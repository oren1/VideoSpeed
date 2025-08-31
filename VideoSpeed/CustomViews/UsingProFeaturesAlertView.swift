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

   
    var onCancel: VoidClosure?
    var onContinue: VoidClosure?
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var priceLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    @IBOutlet weak var mp4View: UIView!
    @IBOutlet weak var fpsView: UIView!
    @IBOutlet weak var soundOffView: UIView!
    @IBOutlet weak var sliderPrecisionView: UIView!
    @IBOutlet weak var proFontView: UIView!
    @IBOutlet weak var mergeVideosView: UIView!
    
    @IBOutlet weak var sliderPrecisionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var soundOffViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var fpsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoFormatViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var proFontViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mergeVideosViewHeightConstraint: NSLayoutConstraint!
   
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
        let freeTrialEnabled = RemoteConfig.remoteConfig().configValue(forKey: "freeTrialEnabled").boolValue
        if freeTrialEnabled {
            let product = UserDataManager.main.products.first {$0.productIdentifier == SpidProducts.freeTrialYearlySubscription }
            priceLabel.text = "7 days free, then \(product!.localizedPrice) / year"
            continueButton.setTitle("Start 7 Days Free Trial", for: .normal)
        }
        else {
            let product = UserDataManager.main.products.first {$0.productIdentifier == SpidProducts.yearlySubscription }
            priceLabel.text = "\(product!.localizedPrice) / year"
        }
//        let showPrice = RemoteConfig.remoteConfig().configValue(forKey: "showingPrice").boolValue
//        if showPrice {
//            let product = UserDataManager.main.products.first {$0.productIdentifier == SpidProducts.yearlySubscription }
//            priceLabel.text = "\(product!.localizedPrice) / year"
//        }
//        else {
//            priceLabel.isHidden = true
//        }
    }
    
    func updateStatus(usingSlider: Bool, soundOff: Bool, fps: Int32, fileType: AVFileType, usingProFont: Bool, mergeVideos: Bool) {
        
//        let isCropFeatureFree = RemoteConfig.remoteConfig().configValue(forKey: "crop_feature_free").numberValue.boolValue

        sliderPrecisionViewHeightConstraint.constant = 0
        sliderPrecisionView.isHidden = true
        
        soundOffViewHeightConstraint.constant = 0
        soundOffView.isHidden = true
        
        fpsViewHeightConstraint.constant = 0
        fpsView.isHidden = true
        
        videoFormatViewHeightConstraint.constant = 0
        mp4View.isHidden = true

        proFontViewHeightConstraint.constant = 0
        proFontView.isHidden = true
        
        mergeVideosViewHeightConstraint.constant = 0
        mergeVideosView.isHidden = true
        
        if usingSlider {
            sliderPrecisionViewHeightConstraint.constant = 24
            sliderPrecisionView.isHidden = false
        }
        if soundOff {
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
        
        if usingProFont {
            proFontViewHeightConstraint.constant = 24
            proFontView.isHidden = false
        }
        
        if mergeVideos {
            mergeVideosViewHeightConstraint.constant = 24
            mergeVideosView.isHidden = false
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        onCancel?()
    }
    
    @IBAction func continueButtonTapped(_ sender: Any) {
        onContinue?()
    }
    
}
