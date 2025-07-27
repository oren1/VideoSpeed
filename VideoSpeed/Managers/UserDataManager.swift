//
//  UserDataManager.swift
//  VideoSpeed
//
//  Created by oren shalev on 23/07/2023.
//

import Foundation
import StoreKit

let twentyFourHoursInSeconds = 24.0 * 60 * 60


class UserDataManager: ObservableObject {
    
    static let main: UserDataManager = UserDataManager()
    var products: [SKProduct]!
    var subscriptionProducts: [Product]!
   
    var currentSpidAsset: SpidAsset!
    var spidAssets: [SpidAsset] = []
    func usingMergeFeature() -> Bool { spidAssets.count > 1 }
    var usingSlider: Bool = false {
        didSet {
            NotificationCenter.default.post(name: Notification.Name("usingSliderChanged"), object: nil)
        }
    }

    @Published
    var textOverlayLabels: [SpidLabel] = []
    
    @Published
    var overlayLabelViews: [LabelView] = [] {
        didSet {
            NotificationCenter.default.post(name: Notification.Name.OverlayLabelViewsUpdated, object: nil)
        }
    }
    
    @Published
    var labelViewsModels: [LabelViewModel] = [] {
        didSet {
            NotificationCenter.default.post(name: Notification.Name.OverlayLabelViewsUpdated, object: nil)
        }
    }
    
    func setSelectedLabeViewModel(_ selectedLabelViewModel: LabelViewModel) {
        for viewModel in labelViewsModels {
            viewModel.selected = false
            if viewModel === selectedLabelViewModel {
                viewModel.selected = true
                self.selectedLabelViewModel = viewModel
            }
        }
        
        NotificationCenter.default.post(name: Notification.Name.SelectedLabelViewChanged, object: nil)
    }
    
    var selectedLabelViewModel: LabelViewModel?
    
    func setSelectedLabeView(_ selectedLabelView: LabelView) {
        for labelView in overlayLabelViews {
            labelView.viewModel.selected = false
            if labelView == selectedLabelView {
                labelView.viewModel.selected = true
                self.selectedLabelView = labelView
            }
        }
        
        NotificationCenter.default.post(name: Notification.Name.SelectedLabelViewChanged, object: nil)
    }
    var selectedLabelView: LabelView?
    
    func getSelectedLabelView() -> LabelView? {
       UserDataManager.main.overlayLabelViews.first { $0.viewModel.selected == true }
    }
    
    var freeFonts: [String] = [
        "TimesNewRomanPSMT",
        "HelveticaNeue",
        "CourierNewPSMT",
    ]
    
    func usingProFont() -> Bool {
        let proFont = labelViewsModels.first(where: { [weak self] labelView in
            guard let self = self else {return false}
            return !freeFonts.contains(labelView.font.fontName)
        })
        if proFont != nil {return true}
        return false
    }
    
    @Published
    var labelViewModels: [LabelViewModel] = []
    
    @Published
    var isUsingCropFeature: Bool = false
    
    func isUsingTrimFeature() async -> Bool {
        guard let originalDuration = try? await currentSpidAsset.getAsset().load(.duration).seconds else { return false }
        let trimmedDuration = await currentSpidAsset.timeRange.duration.seconds
        print("originalDuration ", originalDuration)
        print("trimmedDuration ", trimmedDuration)

        if originalDuration - trimmedDuration > 0.5 { return true }
        return false
    }
    
    var soundOff: Bool = false
    
    func soundOff() async -> Bool {
        for spidAsset in spidAssets {
            if await spidAsset.soundOn == false {
                return true
            }
        }
        return false
    }
    
    var userBenefitStatus: BenefitStatus = .notInvoked
    
    func productforIdentifier(productIndentifier: ProductIdentifier) -> SKProduct? {
        if let product =  products.first(where: { $0.productIdentifier ==  productIndentifier}) {
            return product
        }
        
        return nil
    }

    
    var installationTime: Double? {
        set {
            UserDefaults.standard.set(newValue, forKey: "installationTime")
        }
        get {
            guard UserDefaults.standard.double(forKey: "installationTime") != 0 else {
                return nil
            }
            return UserDefaults.standard.double(forKey: "installationTime")
        }
    }
    
    var userAlreadySeenBenefitView: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "userAlreadySeenBenefitView")
        }
        get {
            UserDefaults.standard.bool(forKey: "userAlreadySeenBenefitView")
        }
    }
    
    func twentyFourHoursPassedSinceInstallation() -> Bool {
        if (installationTime! + twentyFourHoursInSeconds) < Date().timeIntervalSince1970 {
            return true
        }
        return false
    }
    
    var lastApearanceOfPurchaseScreen: Double? {
        set {
            UserDefaults.standard.set(newValue, forKey: "lastPurchaseScreenApearance")
        }
        get {
            guard UserDefaults.standard.double(forKey: "lastPurchaseScreenApearance") != 0 else {
                return nil
            }
            return UserDefaults.standard.double(forKey: "lastPurchaseScreenApearance")
        }
    }
}
