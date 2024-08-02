//
//  MonthlySubscriptionVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 28/06/2024.
//

import UIKit

class MonthlySubscriptionVC: PurchaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        product = UserDataManager.main.products.first {$0.productIdentifier == productIdentifier}
        priceLabel?.text = "\(product.localizedPrice) / month"
    }

}
