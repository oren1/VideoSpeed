//
//  CropSectioVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 11/10/2024.
//

import UIKit

enum CropStatus {
    case done, cropping
}

typealias CropSectionChangedStatusTo = (CropStatus) -> Void

class CropSectioVC: SectionViewController {
   
    @IBOutlet weak var cropButton: UIButton!
    var cropStatus: CropStatus = .cropping
    var cropSectionChangedStatusTo: CropSectionChangedStatusTo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetStatus()

        // Do any additional setup after loading the view.
    }

    func resetStatus() {
        cropStatus = .cropping
        cropButton.setTitle("Done", for: .normal)
    }
    
    @IBAction func cropButtonTapped(_ sender: Any) {
        if cropStatus == .cropping {
            cropStatus = .done
            cropButton.setTitle("Crop", for: .normal)
        }
        else if cropStatus == .done {
            cropStatus = .cropping
            cropButton.setTitle("Done", for: .normal)
        }
        
        cropSectionChangedStatusTo?(cropStatus)
    }
    

}
