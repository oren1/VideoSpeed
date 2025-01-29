//
//  TextSectionVCViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 29/01/2025.
//

import UIKit

class TextSectionVCViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    

    @IBOutlet weak var textCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: "TextCell", bundle: nil)
        textCollectionView.register(nib, forCellWithReuseIdentifier: "TextCell")
        textCollectionView.dataSource = self
        textCollectionView.delegate = self

    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension
