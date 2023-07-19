//
//  FileTypeSectionVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 19/07/2023.
//

import UIKit

class FileTypeSectionVC: SectionViewController {

    @IBOutlet weak var movButton: UIButton!
    @IBOutlet weak var mp4Button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setBorderAndRadius(button: movButton)
        setBorderAndRadius(button: mp4Button)
        setSelectedButton(button: movButton)
        // Do any additional setup after loading the view.
    }

    @IBAction func movButtonTapped(_ sender: Any) {
    }
    
    @IBAction func mp4ButtonTapped(_ sender: Any) {
    }
    

}
