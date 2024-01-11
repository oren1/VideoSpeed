//
//  SubscriptionPurchaseVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 08/01/2024.
//

import UIKit

enum BusinessModel: String {
    case oneTimeCharge = "one_time_charge"
    case yearlySubscription = "yearly_subscription"
}

class SubscriptionPurchaseVC: PurchaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        productIdentifier = SpidProducts.proVersionVersionSubscription
        product = UserDataManager.main.products.first {$0.productIdentifier == productIdentifier}
        priceLabel.text = "(product.localizedPrice) / year"

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
