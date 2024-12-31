//
//  SoundSectionVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 19/08/2023.
//

import UIKit
import FirebaseRemoteConfig
import Combine

class SoundSectionVC: SectionViewController {

    @IBOutlet weak var onButton: UIButton!
    @IBOutlet weak var offButton: UIButton!
    var soundOn: Bool! = true
    var soundStateChanged: SoundStateClosure?
    var sub: AnyCancellable!

    override func viewDidLoad() {
        super.viewDidLoad()
        setBorderAndRadius(button: onButton)
        setBorderAndRadius(button: offButton)
        
        setSelectedButton(button: onButton)
        
//        sub = PublishersManager.main.resetSelectionsPublisher.sink(receiveValue: { [weak self]  notification in
//            guard let self = self else {return}
//            onButtonTapped(onButton)
//        })
    }

    func updateSoundSelection(soundOn: Bool) {
        self.soundOn = soundOn
        if self.soundOn {
            setSelectedButton(button: onButton)
        }
        else {
            setSelectedButton(button: offButton)
        }
    }
    
    @IBAction func onButtonTapped(_ sender: UIButton) {
        soundOn = true
        setSelectedButton(button: onButton)
        soundStateChanged?(soundOn)
    }
    
    @IBAction func offButtonTapped(_ sender: UIButton) {
            soundOn = false
            setSelectedButton(button: offButton)
            soundStateChanged?(soundOn)
    }

}
