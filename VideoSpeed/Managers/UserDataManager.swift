//
//  UserDataManager.swift
//  VideoSpeed
//
//  Created by oren shalev on 23/07/2023.
//

import Foundation
import StoreKit

let twentyFourHoursInSeconds = 24.0 * 60 * 60

class UserDataManager {
    
    static let main: UserDataManager = UserDataManager()
    var products: [SKProduct]!
    var subscriptionProducts: [Product]!
    var usingSlider: Bool = false {
        didSet {
            NotificationCenter.default.post(name: Notification.Name("usingSliderChanged"), object: nil)
        }
    }

    var usingCropFeature: Bool = false {
        didSet {
            NotificationCenter.default.post(name: Notification.Name("usingCropFeatureChanged"), object: nil)
        }
    }
    
    var userBenefitStatus: BenefitStatus = .notInvoked
    
    
    func productforIdentifier(productIndentifier: ProductIdentifier) -> SKProduct? {
        if let product =  products.first(where: { $0.productIdentifier ==  productIndentifier}) {
            return product
        }
        
        return nil
    }
    
    func isNotUsingProFeatures() -> Bool {
        if !usingSlider {
            return true
        }
        return false
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
