//
//  YearlySubscriptionPurchaseVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 17/03/2024.
//

import UIKit

enum PricingModel: String {
    case lifetime = "lifetime"
    case yearly = "yearly"
}

class YearlySubscriptionPurchaseVC: PurchaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        productIdentifier = SpidProducts.yearlySubscription
        product = UserDataManager.main.products.first {$0.productIdentifier == productIdentifier}
        priceLabel?.text = "\(product.localizedPrice) / year"
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}