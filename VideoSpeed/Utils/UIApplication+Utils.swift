//
//  UIApplication+Utils.swift
//  VideoSpeed
//
//  Created by oren shalev on 24/07/2023.
//

import Foundation

import UIKit

extension UIApplication {
   
    static var appVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    func topViewController(
            base: UIViewController? = UIApplication.shared
                .connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?
                .rootViewController
        ) -> UIViewController? {

            if let nav = base as? UINavigationController {
                return topViewController(base: nav.visibleViewController)
            }

            if let tab = base as? UITabBarController {
                return topViewController(base: tab.selectedViewController)
            }

            if let presented = base?.presentedViewController {
                return topViewController(base: presented)
            }

            return base
        }
}
