//
//  AppOpenAd.swift
//  VideoSpeed
//
//  Created by oren shalev on 31/07/2023.
//

import Foundation
import GoogleMobileAds
typealias VoidClosure = () -> ()
class AppOpenAd: NSObject, GADFullScreenContentDelegate {
    
    let minimumAppOpensRequiredToShowAd = 4

    static let manager = AppOpenAd()

    var amountOfAppOpens: Int {
        set {
            UserDefaults.standard.set(newValue, forKey: "amountOfAppOpens")
        }
        get {
            UserDefaults.standard.integer(forKey: "amountOfAppOpens")
        }
    }
    
   
    func addOpenAppCount() {
        amountOfAppOpens = amountOfAppOpens + 1
        print("amount of app open: \(amountOfAppOpens)")
    }
}
