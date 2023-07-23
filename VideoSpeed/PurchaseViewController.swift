//
//  PurchaseViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 23/07/2023.
//

import UIKit
import StoreKit

class PurchaseViewController: UIViewController {

    @IBOutlet weak var priceLabel: UILabel!
    var product: SKProduct!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let productIdentifier = SpidProducts.proVersion
        product = UserDataManager.main.products.first {$0.productIdentifier == productIdentifier}
        priceLabel.text = product.localizedPrice
    }
    
    @IBAction func purchaseButtonTapped(_ sender: Any) {
    }
    
    @IBAction func restoreButtonTapped(_ sender: Any) {
    }
}
