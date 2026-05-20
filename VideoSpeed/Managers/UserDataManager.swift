//
//  UserDataManager.swift
//  VideoSpeed
//
//  Created by oren shalev on 23/07/2023.
//

import Foundation
import StoreKit
import Speech


let twentyFourHoursInSeconds = 24.0 * 60 * 60
let oneMinuteInSeconds = 60.0
let fiveMinutesInSeconds = 5.0 * 60
let twoWeeksInSeconds = 14.0 * 24 * 60 * 60

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
    let hasLaunchedKey = "hasLaunchedBefore"

    var captions: [CaptionItem] = []
    
    func userDontHaveCaptionsYet() -> Bool {
        guard let currentCaptions = UserDataManager.main.currentCaptions else {
            return true
        }
        
        return currentCaptions.count == 0
    }
    
    func usingCaptions() -> Bool {
        guard let currentCaptions = UserDataManager.main.currentCaptions else {
            return false
        }
        
        return currentCaptions.count > 0
    }
    
    @Published
    var transcription: Transcription?
    
    @Published
    var currentCaptions: [Caption]?
    var captionsStyle = CaptionsStyle()

    var languageItems: [LanguageItem] = {
        let locales = Array(SFSpeechRecognizer.supportedLocales())
        let formatter = Locale.current
        
        /* create a custom 'LanguageItem' that will represent a language auto detection
         performed by the SFSpeechRecognizer */
        let autoDetectionLanguageItem: LanguageItem = LanguageItem(identifier: "autoDetection", localizedString: "Auto Detection", isSelected: true)
        
        // I want to support only the languages OpenAI says
        var languageItems = locales
            .sorted {
                let nameA = formatter.localizedString(forIdentifier: $0.identifier) ?? $0.identifier
                let nameB = formatter.localizedString(forIdentifier: $1.identifier) ?? $1.identifier
                return nameA.localizedCaseInsensitiveCompare(nameB) == .orderedAscending
            }
            .map { locale in
                let code = locale.language.languageCode?.identifier ?? ""
                let name = formatter.localizedString(forLanguageCode: code) ?? ""

                return LanguageItem(identifier: code, code: code, localizedString: name)
            }.reduce(into: [LanguageItem]()) { result, item in
                if !result.contains(item) {
                    result.append(item)
                }
            }
        
        languageItems.insert(autoDetectionLanguageItem, at: 0)
        
        return languageItems
    }()

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
    
    func isUsingSliderPrecision() async -> Bool {
        let allowedSpeeds: [Float] = [0.25, 0.5, 1, 1.5, 2]
        for spidAsset in spidAssets {
            if !allowedSpeeds.contains(await spidAsset.speed) {
                return true
            }
        }
        
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
    
    var lastTimePurchaseScreenShownAfterNextTap: Double {
        set {
            UserDefaults.standard.set(newValue, forKey: "lastTimePurchaseScreenShownAfterNextTap")
        }
        get {
            return UserDefaults.standard.double(forKey: "lastTimePurchaseScreenShownAfterNextTap")
        }
    }
    
    var dateToShowPurchaseScreen: Double {
        set {
            UserDefaults.standard.set(newValue, forKey: "dateToShowPurchaseScreen")
        }
        get {
            return UserDefaults.standard.double(forKey: "dateToShowPurchaseScreen")
        }
    }
    
    func twoWeeksPassedSincePurchaseScreenShownAfterNextTap() -> Bool {
        let lastShown = lastTimePurchaseScreenShownAfterNextTap
        guard lastShown != 0 else { return false }
        return (lastShown + twoWeeksInSeconds) < Date().timeIntervalSince1970
    }
    
    func fiveMinutesPassedSincePurchaseScreenShownAfterNextTap() -> Bool {
        let lastShown = lastTimePurchaseScreenShownAfterNextTap
        guard lastShown != 0 else { return false }
        return (lastShown + fiveMinutesInSeconds) < Date().timeIntervalSince1970
    }
    
    func setHasLaunchedKeyIfNeeded() {
        if !UserDefaults.standard.bool(forKey: hasLaunchedKey) {
            print("First launch ever!")
            UserDefaults.standard.set(true, forKey: hasLaunchedKey)
        }
    }
   
    func hasLaunchedAppBefore() -> Bool {
        return UserDefaults.standard.bool(forKey: hasLaunchedKey)
    }
    
    var sentNotificationPermissionAnalyticStatus : Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: "sentNotificationPermissionAnalyticStatus")
        }
        get {
            return UserDefaults.standard.bool(forKey: "sentNotificationPermissionAnalyticStatus")
        }
    }
    
    func setGiftDueDate(giftDueDate: Date) {
        let defaults = UserDefaults.standard

        if let oldDueDate = defaults.object(forKey: "giftDueDate") as? Date {
           if oldDueDate < Date() {
                UserDefaults.standard.set(giftDueDate, forKey: "giftDueDate")
            }
        }
        else {
            UserDefaults.standard.set(giftDueDate, forKey: "giftDueDate")
        }
      
    }
    
    func isGiftActive() -> Bool {
        let defaults = UserDefaults.standard

        guard let giftDueDate = defaults.object(forKey: "giftDueDate") as? Date else {
            return false
        }

        return Date() < giftDueDate
    }
}
