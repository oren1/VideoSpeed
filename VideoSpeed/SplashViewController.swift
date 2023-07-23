//
//  SplashViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 23/07/2023.
//

import UIKit

class SplashViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        SpidProducts.store.requestProducts { [weak self] success, products in
            if let products = products, success {
                UserDataManager.main.products = products
                DispatchQueue.main.async {
                    let mainViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
                    self?.navigationController?.pushViewController(mainViewController, animated: false)
                }

            }
        }
    }
}
