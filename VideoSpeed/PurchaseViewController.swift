//
//  PurchaseViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 23/07/2023.
//

import UIKit
import StoreKit

class PurchaseViewController: UIViewController {

    var product: SKProduct!

    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var oneTimeChargeLabel: UILabel!
    var onDismiss: VoidClosure?
    lazy var loadingView: LoadingView = {
        loadingView = LoadingView()
        return loadingView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let productIdentifier = SpidProducts.proVersion
        product = UserDataManager.main.products.first {$0.productIdentifier == productIdentifier}
        priceLabel.text = product.localizedPrice
        
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            backButton.isHidden = true
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseCompleted), name: .IAPManagerPurchaseNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(restoreCompleted), name: .IAPManagerRestoreNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseFailed), name: .IAPManagerPurchaseFailedNotification, object: nil)
    }
    
    @IBAction func purchaseButtonTapped(_ sender: Any) {
        guard SpidProducts.store.canMakePayments() else {
            showCantMakePaymentAlert()
            return
        }
        
        guard let product = UserDataManager.main.productforIdentifier(productIndentifier: SpidProducts.proVersion) else {
            return
        }
        
        showLoading()
        SpidProducts.store.buyProduct(product)
    }
    
    @IBAction func restoreButtonTapped(_ sender: Any) {
        showLoading()
        SpidProducts.store.restorePurchases()
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        onDismiss?()
        dismiss(animated: true)
    }
    
    
    func showCantMakePaymentAlert() {
        let alertController = UIAlertController(title: "Error", message: "Payment Not Available", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(action)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - NotificationCenter Selectors
    @objc func purchaseCompleted(notification: Notification) {
        onDismiss?()
        hideLoading()
        dismiss(animated: true)
    }

    
    
    @objc func restoreCompleted(notification: Notification) {
        onDismiss?()
        hideLoading()
        dismiss(animated: true)
    }
    
    @objc func purchaseFailed(notification: Notification) {
        hideLoading()
        if let text = notification.object as? String {
            let alertController = UIAlertController(title: text, message: nil, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(action)
            present(alertController, animated: true, completion: nil)
        }
    }
 
    func showLoading() {
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
        enablePresentationDismiss()
        loadingView.activityIndicator.stopAnimating()
        loadingView.removeFromSuperview()
    }
    
    func disablePresentaionDismiss() {
        isModalInPresentation = true
    }
   
    func enablePresentationDismiss() {
        isModalInPresentation = false
    }
}
