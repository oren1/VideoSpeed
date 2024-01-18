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
    case subscription = "subscription"
}

class SubscriptionPurchaseVC: PurchaseViewController {
    
    var subscriptionProduct: Product!
    
    @IBOutlet weak var discountView: UIView!
    @IBOutlet weak var discountLabel: UILabel!

    @IBOutlet weak var bestOptionView: SubscriptionOptionView!
    @IBOutlet weak var secondOptionView: SubscriptionOptionView!
    
    @IBOutlet weak var yearlyDot: UIImageView!
    @IBOutlet weak var halfYearlyDot: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setSubscriptionOptionViews()
        bestOptionView.select()
        discountView.layer.cornerRadius = discountView.frame.height / 8
        
        productIdentifier = SpidProducts.yearlySubscription
    }
    
    @IBAction override func purchaseButtonTapped(_ sender: Any) {
                Task {
                    do {
                        showLoading()
                        let products = try await Product.products(for: [productIdentifier])
                        subscriptionProduct =  products.first
                        let purchaseResult = try await subscriptionProduct?.purchase()
                        switch purchaseResult {
                        case .success(let verificationResult):
                            switch verificationResult {
                            case .verified(let transaction):
                                print("transaction.productID \(transaction.productID)")
                                // Give the user access to purchased content.
                                SpidProducts.store.updateIdentifier(identifier: transaction.productID)
                                AnalyticsManager.purchaseEvent()
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
    @IBAction func bestOfferOptionViewTapped(gestureRecognizer: UITapGestureRecognizer) {
        productIdentifier = SpidProducts.yearlySubscription
        bestOptionView.select()
        secondOptionView.unSelect()
    }
    
    @IBAction func secondOptionViewTapped(gestureRecognizer: UITapGestureRecognizer) {
        productIdentifier = SpidProducts.monthlySubscription
        secondOptionView.select()
        bestOptionView.unSelect()
    }
    
    // MARK: Custom Logic
    func percentageOff(fullPrice: NSDecimalNumber, discountPrice: NSDecimalNumber) -> String {
        let percentage =  (1 - (discountPrice.dividing(by: fullPrice).floatValue)) * 100
        return "\(Int(percentage))% OFF"
    }
    
    func priceDividedBy(segments: NSDecimalNumber, of product: SKProduct) -> String {
        let priceForSegment = product.price.dividing(by: segments)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        let segmentPriceString = formatter.string(from: priceForSegment)!
        return segmentPriceString
    }
    
    // MARK: - UI
    func setSubscriptionOptionViews() {
         // 1. grab the products for the productIdentifier's
        let yearlySubscriptionProduct = UserDataManager.main.products.first {$0.productIdentifier == SpidProducts.yearlySubscription }
        let monthlySubscriptionProduct = UserDataManager.main.products.first {$0.productIdentifier == SpidProducts.monthlySubscription }

         // 2. set the local price to the 'priceLabel' of the view
        bestOptionView.priceLabel.text = "Yearly \(yearlySubscriptionProduct!.localizedPrice)"
        secondOptionView.priceLabel.text = "Monthly \(monthlySubscriptionProduct!.localizedPrice)"

        // 3. set the monthly amount to the descriptionLabel of the view
        let fullPrice = monthlySubscriptionProduct!.price.multiplying(by: 12)
        discountLabel.text = percentageOff(fullPrice: fullPrice, discountPrice: yearlySubscriptionProduct!.price)
        
        
        let segmentPrice = priceDividedBy(segments: 12, of: yearlySubscriptionProduct!)
        bestOptionView.descriptionLabel.text = "\(segmentPrice)/month"
        secondOptionView.descriptionLabel.text = "\(monthlySubscriptionProduct!.localizedPrice)/month"
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
