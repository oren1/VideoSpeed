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

    @IBOutlet weak var cropView: UIView!
    @IBOutlet weak var cropViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cropViewBottomHeightConstraint: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()
        product = UserDataManager.main.products.first {$0.productIdentifier == productIdentifier}
        priceLabel?.text = "\(product.localizedPrice) / year"
      
        let isCropFeatureFree = RemoteConfig.remoteConfig().configValue(forKey: "crop_feature_free").numberValue.boolValue
        
        if isCropFeatureFree {
            cropView.isHidden = true
            cropViewHeightConstraint.constant = 0
            cropViewBottomHeightConstraint.constant = 0
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
