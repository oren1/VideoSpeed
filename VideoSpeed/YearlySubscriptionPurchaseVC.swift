//
//  YearlySubscriptionPurchaseVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 17/03/2024.
//

import UIKit
import FirebaseRemoteConfig

enum SubscriptionModel: String {
    case weekly = "weekly"
    case monthly = "monthly"
}

class YearlySubscriptionPurchaseVC: PurchaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        product = UserDataManager.main.products.first {$0.productIdentifier == productIdentifier}
        if productIdentifier == SpidProducts.freeTrialYearlySubscription {
            priceLabel.text = "7 days free, then \(product!.localizedPrice) / year"
        }
        else {
            priceLabel?.text = "\(product.localizedPrice) / year"
        }
        
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
