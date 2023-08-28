//
//  SoundSectionVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 19/08/2023.
//

import UIKit
import FirebaseRemoteConfig

class SoundSectionVC: SectionViewController {

    @IBOutlet weak var onButton: UIButton!
    @IBOutlet weak var offButton: UIButton!
    var soundOn: Bool! = true
    var soundStateChanged: SoundStateClosure?

    override func viewDidLoad() {
        super.viewDidLoad()
        setBorderAndRadius(button: onButton)
        setBorderAndRadius(button: offButton)
        
        setSelectedButton(button: onButton)

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
    
    @IBAction func onButtonTapped(_ sender: Any) {
        soundOn = true
        setSelectedButton(button: onButton)
        soundStateChanged?(soundOn)
    }
    
    @IBAction func offButtonTapped(_ sender: Any) {
       
            guard let purchasedProduct = SpidProducts.store.userPurchasedProVersion() else {
                let experimentProFeatures = RemoteConfig.remoteConfig().configValue(forKey: "experimentProFeatures").boolValue

                if experimentProFeatures {
                    soundOn = false
                    setSelectedButton(button: offButton)
                    soundStateChanged?(soundOn)
                }
                else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                        guard let self = self else {return}
                        self.userNeedsToPurchase?()
                    }
                }
                
                return
            }
            print("purchasedProduct \(purchasedProduct)")
            
            soundOn = false
            setSelectedButton(button: offButton)
            soundStateChanged?(soundOn)
        
    }

}
