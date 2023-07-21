//
//  FileTypeSectionVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 19/07/2023.
//

import UIKit
import AVFoundation

typealias FileTypeClosure = (AVFileType) -> ()

class FileTypeSectionVC: SectionViewController {

    @IBOutlet weak var movButton: UIButton!
    @IBOutlet weak var mp4Button: UIButton!
    
    var fileType: AVFileType = .mov
    var fileTypeDidChange: FileTypeClosure?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setBorderAndRadius(button: movButton)
        setBorderAndRadius(button: mp4Button)
        
        setSelectedButton(button: movButton)
    }

    @IBAction func movButtonTapped(_ sender: UIButton) {
        fileType = .mov
        fileTypeDidChange?(fileType)
        setSelectedButton(button: sender)
    }
    
    @IBAction func mp4ButtonTapped(_ sender: UIButton) {
        fileType = .mp4
        fileTypeDidChange?(fileType)
        setSelectedButton(button: sender)
    }
    

}
