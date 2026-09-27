//
//  FPSSectionVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 19/07/2023.
//

import UIKit
import FirebaseRemoteConfig
import Combine

enum FPS: Int {
    case thirty = 30
    case sixty = 60
}
class FPSSectionVC: SectionViewController {

    typealias FPSClosure = (Int32) -> ()
    
    @IBOutlet weak var thirtyButton: UIButton!
    @IBOutlet weak var sixtyButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    
    var fpsDidChange: FPSClosure?

    var fps: Int32 = 30 {
        didSet {
            guard fps != oldValue else { return }
            fpsDidChange?(fps)
        }
    }
    
    let fpsOptions = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,60]
    var sub: AnyCancellable!

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark

        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.setValue(UIColor.white, forKey: "textColor")
        syncPickerSelection()
    }

    /// Updates the picker (and stored fps) without notifying `fpsDidChange` — used when restoring from a project.
    func syncUI(to value: Int32) {
        let callback = fpsDidChange
        fpsDidChange = nil
        fps = value
        fpsDidChange = callback
        if isViewLoaded {
            syncPickerSelection()
        }
    }

    private func syncPickerSelection() {
        let row = fpsOptions.firstIndex(of: Int(fps)) ?? fpsOptions.firstIndex(of: 30) ?? 0
        pickerView.selectRow(row, inComponent: 0, animated: false)
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

extension FPSSectionVC: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return fpsOptions.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let fps = fpsOptions[row]
        return String(fps)
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 38
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            fps = Int32(fpsOptions[row])
            print(fps)
    }
}
