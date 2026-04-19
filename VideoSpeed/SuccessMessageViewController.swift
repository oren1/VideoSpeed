//
//  SuccessMessageViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 01/08/2023.
//

import UIKit
import SwiftUI

class SuccessMessageViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppStoreReviewManager.requestReviewIfAppropriate()
    }
    
    
    @IBAction func backButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
}
