//
//  ColorEditSectionVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 30/04/2025.
//

import UIKit

typealias ColorSelectionClosure = (UIColor) -> Void
let colorCellIdentifier = "ColorCollectionViewCell"
let clearColorCellIdentifier = "ClearColorCVCell"


class ColorEditSectionVC: UIViewController {
    
    var alpha: CGFloat = 1
    var selectedColor: UIColor!
    @IBOutlet weak var opacityLabel: UILabel!
    
    private(set) var sectionInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
    @IBOutlet weak var collectionView: UICollectionView!
    var didSelectColor: ColorSelectionClosure?
    let spidColors: [SpidColor] = [
        SpidColor(color: UIColor.clear), // White
        SpidColor(color: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)), // White
        SpidColor(color: UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)),       // Black
        SpidColor(color: UIColor(red: 255/255, green: 0/255, blue: 0/255, alpha: 1)),     // Red
        SpidColor(color: UIColor(red: 230/255, green: 57/255, blue: 70/255, alpha: 1)),   // Softer Red
        SpidColor(color: UIColor(red: 255/255, green: 255/255, blue: 0/255, alpha: 1)),   // Yellow
        SpidColor(color: UIColor(red: 241/255, green: 196/255, blue: 15/255, alpha: 1)),  // Soft Yellow
        SpidColor(color: UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: 1)),  // Blue
        SpidColor(color: UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1)),  // Twitter Blue
        SpidColor(color: UIColor(red: 255/255, green: 105/255, blue: 180/255, alpha: 1)), // Pink
        SpidColor(color: UIColor(red: 255/255, green: 192/255, blue: 203/255, alpha: 1)), // Light Pink
        SpidColor(color: UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: 1)),  // Green
        SpidColor(color: UIColor(red: 39/255, green: 174/255, blue: 96/255, alpha: 1)),   // Dark Green
        SpidColor(color: UIColor(red: 255/255, green: 165/255, blue: 0/255, alpha: 1)),   // Orange
        SpidColor(color: UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)),  // Dark Orange
        SpidColor(color: UIColor(red: 155/255, green: 89/255, blue: 182/255, alpha: 1)),  // Purple
        SpidColor(color: UIColor(red: 142/255, green: 68/255, blue: 173/255, alpha: 1)),  // Dark Purple
        SpidColor(color: UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 1)), // Gray
        SpidColor(color: UIColor(red: 189/255, green: 195/255, blue: 199/255, alpha: 1))  // Light Gray
    ]

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let colorCell = UINib(nibName: "ColorCollectionViewCell", bundle: nil)
        collectionView.register(colorCell, forCellWithReuseIdentifier: colorCellIdentifier)
    
        let clearColorCell = UINib(nibName: "ClearColorCVCell", bundle: nil)
        collectionView.register(clearColorCell, forCellWithReuseIdentifier: clearColorCellIdentifier)
    
        selectedColor = spidColors[2].color
        
        collectionView.reloadData()
    }

    @IBAction func sliderValueChanged(_ slider: UISlider) {
        alpha = CGFloat(slider.value / 100)
        opacityLabel.text = String(Int(slider.value))
        self.didSelectColor?(selectedColor.withAlphaComponent(alpha))
    }
    
}


extension ColorEditSectionVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Selection of the plus button
        spidColors.forEach({ $0.isSelected = false})
        let spidColor = spidColors[indexPath.row]
        spidColor.isSelected = true
        selectedColor = spidColor.color
        
        if spidColor.color == .clear {
            self.didSelectColor?(spidColor.color)
        }
        else {
            self.didSelectColor?(spidColor.color.withAlphaComponent(alpha))
        }
        
        collectionView.reloadData()
    }
}

extension ColorEditSectionVC: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
     return 1
   }

    func collectionView(
     _ collectionView: UICollectionView,
     numberOfItemsInSection section: Int
   ) -> Int {
       return spidColors.count
   }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let spidColor = spidColors[indexPath.row]
        let cell: UICollectionViewCell
        
        if spidColor.color == .clear {
             cell = collectionView.dequeueReusableCell(
               withReuseIdentifier: clearColorCellIdentifier,
               for: indexPath
            ) as! ClearColorCVCell
        }
        else {
             let colorCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: colorCellIdentifier,
               for: indexPath
            ) as! ColorCollectionViewCell
            
            colorCell.colorView.backgroundColor = spidColor.color
            cell = colorCell
        }
        

        if spidColor.isSelected {
            cell.backgroundColor = .black
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.borderWidth = 2
        }
        else {
            cell.backgroundColor = .clear
            cell.layer.borderColor = UIColor.clear.cgColor
            cell.layer.borderWidth = 0
        }

     return cell
   }
}

extension ColorEditSectionVC: UICollectionViewDelegateFlowLayout {
    func collectionView(
      _ collectionView: UICollectionView,
      layout collectionViewLayout: UICollectionViewLayout,
      sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
      // 2
        let heightPaddingSpace = sectionInsets.top * 2
        let availableHeight = collectionView.frame.height - heightPaddingSpace
        
        return CGSize(width: availableHeight, height: availableHeight)
    
    }

    // 3
    func collectionView(
      _ collectionView: UICollectionView,
      layout collectionViewLayout: UICollectionViewLayout,
      insetForSectionAt section: Int
    ) -> UIEdgeInsets {
      return sectionInsets
    }

    // 4
    func collectionView(
      _ collectionView: UICollectionView,
      layout collectionViewLayout: UICollectionViewLayout,
      minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
      return sectionInsets.left
    }
    
    
}
