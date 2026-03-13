//
//  UIViewController+Extension.swift
//  VideoSpeed
//
//  Created by oren shalev on 07/09/2023.
//

import Foundation
import UIKit
import FirebaseRemoteConfig
import StoreKit
import SwiftUI

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
    
    func showVerificationError(error: VerificationResult<StoreKit.Transaction>.VerificationError) {
        let alert = UIAlertController(
          title: "Could't Complete Purchase",
          message: error.localizedDescription,
          preferredStyle: .alert)
        alert.addAction(UIAlertAction(
          title: "OK",
          style: UIAlertAction.Style.cancel,
          handler: { [weak self] _ in
              self?.hideLoading()
          }))
        present(alert, animated: true, completion: nil)
    }
    
    func showLoading() {
        let loadingView = LoadingView()
        loadingView.backgroundColor = .clear
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
    
    func showGiftPopup(daysFree: Int) {
            let popupView = GiftPopupView(daysFree: daysFree) {
                      self.dismiss(animated: false)
            }

              let hostingVC = UIHostingController(rootView: popupView)

            hostingVC.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
            hostingVC.view.backgroundColor = UIColor.clear

            present(hostingVC, animated: false)
    }
}
