//
//  UserDataManager.swift
//  VideoSpeed
//
//  Created by oren shalev on 23/07/2023.
//

import Foundation
import StoreKit

class UserDataManager {
    
    static let main: UserDataManager = UserDataManager()
    var products: [SKProduct]!
    var subscriptionProducts: [Product]!
    var usingSlider: Bool = false {
        didSet {
            NotificationCenter.default.post(name: Notification.Name("usingSliderChanged"), object: nil)
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
    

}
