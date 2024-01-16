//
//  SubscriptionPurchaseVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 08/01/2024.
//

import UIKit
import StoreKit

enum BusinessModel: String {
    case oneTimeCharge = "one_time_charge"
    case yearlySubscription = "subscription"
}

class SubscriptionPurchaseVC: PurchaseViewController {
    
    var subscriptionProduct: Product!
    
    @IBOutlet weak var discountView: UIView!
    @IBOutlet weak var halfYearlyOptionView: SubscriptionOptionView!
    @IBOutlet weak var monthlyOptionView: SubscriptionOptionView!
    
    @IBOutlet weak var yearlyDot: UIImageView!
    @IBOutlet weak var halfYearlyDot: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        halfYearlyOptionView.select()
        discountView.layer.cornerRadius = discountView.frame.height / 8
        productIdentifier = SpidProducts.proVersionVersionSubscriptionTest
        priceLabel?.text = "\(product.localizedPrice) / year"
    }
    
    @IBAction override func purchaseButtonTapped(_ sender: Any) {
                Task {
                    do {
                        showLoading()
                        let products = try await Product.products(for: [SpidProducts.proVersionVersionSubscriptionTest])
                        subscriptionProduct =  products.first
                        let purchaseResult = try await subscriptionProduct?.purchase()
                        switch purchaseResult {
                        case .success(let verificationResult):
                            switch verificationResult {
                            case .verified(let transaction):
                                print("transaction.productID \(transaction.productID)")
                                // Give the user access to purchased content.
                                SpidProducts.store.updateIdentifier(identifier: transaction.productID)
                                subscriptionPurchaseCompleted()
                                // Complete the transaction after providing
                                // the user access to the content.
                                await transaction.finish()
                            case .unverified(let transaction, let verificationError):
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
    
    
    // MARK: - Actions
    @IBAction func halfYearlyOptionViewTapped(gestureRecognizer: UITapGestureRecognizer) {
        halfYearlyOptionView.select()
        monthlyOptionView.unSelect()
    }
    
    @IBAction func monthlyOptionViewTapped(gestureRecognizer: UITapGestureRecognizer) {
        monthlyOptionView.select()
        halfYearlyOptionView.unSelect()
    }
    
    
    // MARK: - UI
    func serSubscriptionOptionView() {
            
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

}
