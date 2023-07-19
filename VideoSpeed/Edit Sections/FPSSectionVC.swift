//
//  FPSSectionVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 19/07/2023.
//

import UIKit
enum FPS: Int {
    case thirty = 30
    case sixty = 60
}
class FPSSectionVC: SectionViewController {

    typealias FPSClosure = (Int32) -> ()
    
    @IBOutlet weak var thirtyButton: UIButton!
    @IBOutlet weak var sixtyButton: UIButton!

    var fpsDidChange: FPSClosure?

    var fps: Int32 = 30 {
        didSet {
            fpsDidChange?(fps)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setBorderAndRadius(button: thirtyButton)
        setBorderAndRadius(button: sixtyButton)
        setSelectedButton(button: thirtyButton)
    }

    
    
    
    @IBAction func thirtyButtonTapped(_ sender: Any) {
        fps = 30
        setSelectedButton(button: thirtyButton)
    }
    @IBAction func sixtyButtonTapped(_ sender: Any) {
        fps = 60
        setSelectedButton(button: sixtyButton)
    }
    
    
}
