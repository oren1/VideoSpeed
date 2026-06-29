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
        
        NotificationCenter.default.addObserver(self, selector: #selector(videoSelectionChanged), name: Notification.Name.VideoSelectionChanged, object: nil)
        
        setBorderAndRadius(button: onButton)
        setBorderAndRadius(button: offButton)
        
        setSelectedButton(button: onButton)

        Task { @MainActor in
            await videoSelectionChangedAsync()
        }
    }

    func updateSoundSelection(soundOn: Bool) {
        self.soundOn = soundOn
        if self.soundOn {
            setSelectedButton(button: onButton)
        } else {
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

    private func videoSelectionChangedAsync() async {
        guard let spidAsset = UserDataManager.main.currentSpidAsset else { return }
        let isImage = await spidAsset.isImageClip
        view.isUserInteractionEnabled = !isImage
        view.alpha = isImage ? 0.4 : 1.0
        guard !isImage else { return }
        let soundOn = await spidAsset.soundOn
        updateSoundSelection(soundOn: soundOn)
    }
    
    @objc private func videoSelectionChanged() {
        Task { @MainActor in
            await videoSelectionChangedAsync()
        }
    }
}
