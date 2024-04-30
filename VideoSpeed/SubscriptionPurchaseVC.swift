//
//  SubscriptionPurchaseVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 08/01/2024.
//

import UIKit
import StoreKit
import SafariServices

enum BusinessModel: String {
    case oneTimeCharge = "one_time_charge"
    case subscription = "subscription"
}

class SubscriptionPurchaseVC: PurchaseViewController {
        
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
    
    @IBAction override func termsOfUse(_ sender: Any) {
        showLink("https://spid-app-info.onrender.com/terms-of-use.html")
    }
    
    @IBAction override func privacyPolicyButtonTapped(_ sender: Any) {
        showLink("https://spid-app-info.onrender.com/privacy-policy.html")
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
    
}
