//
//  UIViewController+Extension.swift
//  VideoSpeed
//
//  Created by oren shalev on 07/09/2023.
//

import Foundation
import UIKit
import FirebaseRemoteConfig

let loadinViewTag = 12

extension UIViewController {
    
    func getPurchaseViewController() -> PurchaseViewController {
        let rawValue = RemoteConfig.remoteConfig().configValue(forKey: "subscription_model").stringValue!
        let subscriptionModel = SubscriptionModel(rawValue: rawValue)
        
        let purchaseViewController: PurchaseViewController
        
        switch subscriptionModel {
        case .weekly:
            purchaseViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WeeklySubscriptionVC") as! WeeklySubscriptionVC
        default:
            purchaseViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MonthlySubscriptionVC") as! MonthlySubscriptionVC
        }
    
        return purchaseViewController
    }
    
    func showLoading() {
        let loadingView = LoadingView()
//        loadingView.layer.opacity = opacity ?? 1
        loadingView.tag = loadinViewTag
        disablePresentaionDismiss()
        loadingView.activityIndicator.startAnimating()
        view.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false

        let constraints = [
            loadingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            loadingView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            loadingView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }

    func hideLoading() {
        let loadingView = view.viewWithTag(loadinViewTag) as? LoadingView
        enablePresentationDismiss()
        loadingView?.activityIndicator.stopAnimating()
        loadingView?.removeFromSuperview()
    }

    func disablePresentaionDismiss() {
        isModalInPresentation = true
    }

    func enablePresentationDismiss() {
        isModalInPresentation = false
    }

    func remove() {
            willMove(toParent: nil)
            view.removeFromSuperview()
            removeFromParent()
    }
}
