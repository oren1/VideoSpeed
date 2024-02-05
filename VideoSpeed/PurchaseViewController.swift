//
//  PurchaseViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 23/07/2023.
//

import UIKit
import StoreKit
import FirebaseRemoteConfig
import FirebaseAnalytics

enum PriceVariantType: Int {
    case baseLine = 1, tenDollars
}

class PurchaseViewController: UIViewController {

    var product: SKProduct!
    var productIdentifier: ProductIdentifier!
    
    
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
        productIdentifier = SpidProducts.proVersion
        product = UserDataManager.main.products.first {$0.productIdentifier == productIdentifier}
        priceLabel?.text = product.localizedPrice
        
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            backButton.isHidden = true
        }
        
    }
    
    
    @IBAction func purchaseButtonTapped(_ sender: Any) {
                Task {
                    do {
                        showLoading()
                        let products = try await Product.products(for: [productIdentifier])
                        let product =  products.first
                        let purchaseResult = try await product?.purchase()
                        switch purchaseResult {
                        case .success(let verificationResult):
                            switch verificationResult {
                            case .verified(let transaction):
                                // Give the user access to purchased content.
                                print("verified transaction \(transaction)")
                                Analytics.logTransaction(transaction)
                                SpidProducts.store.updateIdentifier(identifier: transaction.productID)
                                AnalyticsManager.purchaseEvent()
                                purchaseCompleted()
                                // Complete the transaction after providing
                                // the user access to the content.
                                await transaction.finish()
                            case .unverified(_, let verificationError):
                                // Handle unverified transactions based
                                // on your business model.
                                showVerificationError(error: verificationError)
                                
                            }
                        case .pending:
                            // The purchase requires action from the customer.
                            // If the transaction completes,
                            // it's available through Transaction.updates.
                            self.hideLoading()

                            break
                        case .userCancelled:
                            // The user canceled the purchase.
                            self.hideLoading()
                            break
                        @unknown default:
                            self.hideLoading()
                            break
                        }
                    }
                    catch {
                        print("fatal error: couldn't get subscription products from Product struct")
                    }
        
                }
    }
    
    
    @IBAction func restoreButtonTapped(_ sender: Any) {
        Task {
            do {
                showLoading()
                try await AppStore.sync() // syncs all transactions from the appstore
                let refreshStatus =  try await SpidProducts.store.refreshPurchasedProducts()
                switch refreshStatus {
                case .foundActivePurchase:
                    showRefreshAlert(title: "You're All Set")
                case .noPurchasesFound:
                    showRefreshAlert(title: "No Active Subscriptions Found")
                }
            }
            catch {
                print(error)
            }
            
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        onDismiss?()
        dismiss(animated: true)
    }
    
    
 
    func showVerificationError(error: VerificationResult<Transaction>.VerificationError) {
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
    
    func showRefreshAlert(title: String)  {
        let alert = UIAlertController(
          title: title,
          message: nil,
          preferredStyle: .alert)
        alert.addAction(UIAlertAction(
          title: "OK",
          style: UIAlertAction.Style.cancel,
          handler: { [weak self] _ in
              self?.restoreCompleted()
          }))
        present(alert, animated: true, completion: nil)
    }
    
    func purchaseCompleted() {
        onDismiss?()
        hideLoading()
        dismiss(animated: true)
    }
    
    func restoreCompleted() {
        onDismiss?()
        hideLoading()
        dismiss(animated: true)
    }
}
