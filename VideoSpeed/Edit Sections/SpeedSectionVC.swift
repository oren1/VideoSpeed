//
//  SpeedSectionVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 16/07/2023.
//

import UIKit
import FirebaseRemoteConfig
import Combine

typealias SpeedClosure = (Float) -> Void

class SpeedSectionVC: SectionViewController {

    @IBOutlet weak var point25Button: UIButton!
    @IBOutlet weak var point5Button: UIButton!
    @IBOutlet weak var oneButton: UIButton!
    @IBOutlet weak var onePoint5Button: UIButton!
    @IBOutlet weak var twoButton: UIButton!

    
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var speedLabel: UILabel!
    
    var speedDidChange: SpeedClosure?
    var sliderValueChange: SpeedClosure?
    var freeVersionAllowedSpeeds = [0.25, 0.5, 1, 1.5, 2]
    var speed: Float = 1 {
        didSet {
            speedLabel?.text = "\(speed)x"
        }
    }
    
    var sub: AnyCancellable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(usingSliderChanged), name: Notification.Name("usingSliderChanged"), object: nil)
        
        sub = PublishersManager.main.resetSelectionsPublisher.sink(receiveValue: { [weak self]  notification in
            guard let self = self else {return}
            oneButtonTapped(oneButton)
        })
        
        setBorderAndRadius(button: point25Button)
        setBorderAndRadius(button: point5Button)
        setBorderAndRadius(button: oneButton)
        setBorderAndRadius(button: onePoint5Button)
        setBorderAndRadius(button: twoButton)

        setSelectedButton(button: oneButton)
    }

    @objc func usingSliderChanged() {}
   

    @IBAction func point25ButtonTapped(_ sender: UIButton) {
        setSelectedButton(button: sender)
        speed = 0.25
        slider.value = 5
        UserDataManager.main.usingSlider = false
        speedDidChange?(speed)

    }
    @IBAction func point5ButtonTapped(_ sender: UIButton) {
        setSelectedButton(button: sender)
        speed = 0.5
        slider.value = 10
        UserDataManager.main.usingSlider = false
        speedDidChange?(speed)
    }
    @IBAction func oneButtonTapped(_ sender: UIButton) {
        setSelectedButton(button: sender)
        speed = 1
        slider.value = 19
        UserDataManager.main.usingSlider = false
        speedDidChange?(speed)

    }
    @IBAction func onePoint5ButtonTapped(_ sender: UIButton) {
        setSelectedButton(button: sender)
        speed = 1.5
        slider.value = 20.5
        UserDataManager.main.usingSlider = false
        speedDidChange?(speed)

    }
    @IBAction func twoButtonTapped(_ sender: UIButton) {
        setSelectedButton(button: sender)
        speed = 2
        slider.value = 21
        UserDataManager.main.usingSlider = false
        speedDidChange?(speed)
    }

    
    @IBAction func onSliderChange(_ sender: Any) {
        setButtonUnselected(button: currentSelectedButton)
//        currentSelectedButton?.tintColor = .link
        let slider = sender as! UISlider
        speed = convertSliderValue(value: slider.value)
        
        if [0.5, 1, 1.5, 2].contains(speed) { /* If the slider value has changed to one of
            the allowed values of the free version then consider it as not using the slider.
            this will let the "EditViewController" know that it shouldn't show the "proVersion" button.
        */
            UserDataManager.main.usingSlider = false
        }
        else {
            UserDataManager.main.usingSlider = true

        }
        sliderValueChange?(speed)
    }

    @IBAction func sliderReleased(_ sender: Any) {
            let slider = sender as! UISlider
            speed = convertSliderValue(value: slider.value)
            speedDidChange?(speed)
    }
    
    func convertSliderValue(value: Float) -> Float {
        
        if value < 20 {
            switch Int(value) {
            case 1...2:
                return 0.1
            case 3...4:
                return 0.2
            case 5...6:
                return 0.3
            case 7...8:
                return 0.4
            case 9...10:
                return 0.5
            case 11...12:
                return 0.6
            case 13...14:
                return 0.7
            case 15...16:
                return 0.8
            case 17...18:
                return 0.9
            case 19...20:
                return 1
                
            default:
                return 1
            }
        }
      
        else {
            var newValue = value - 19
            newValue = Float(round(10 * newValue) / 10)
            return newValue
        }
    }
    
   
  
    
}
