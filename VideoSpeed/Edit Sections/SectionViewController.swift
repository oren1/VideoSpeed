//
//  SectionViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 19/07/2023.
//

import UIKit
import FirebaseRemoteConfig

typealias VoidClousure = () -> ()

class SectionViewController: UIViewController {
    var currentSelectedButton: UIButton!
    var userNeedsToPurchase: VoidClousure?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear

    }
    
    
    func setBorderAndRadius(button: UIButton) {
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 8
        button.tintColor = .clear
    }
    
    func setSelectedButton(button: UIButton) {
        currentSelectedButton?.tintColor = UIColor.black
        button.tintColor = .link
        currentSelectedButton = button
    }

    func setButtonUnselected(button: UIButton) {
        button.tintColor = .black
    }
}
