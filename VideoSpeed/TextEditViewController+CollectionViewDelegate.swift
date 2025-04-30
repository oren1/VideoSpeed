//
//  TextEditViewController+CollectionViewDelegate.swift
//  VideoSpeed
//
//  Created by oren shalev on 29/04/2025.
//

import Foundation
import UIKit

extension TextEditViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let menuItem = textEditMenuItems[indexPath.row]
        textEditMenuItems.forEach({ $0.selected = false })
        menuItem.selected = true
        collectionView.reloadData()
    }
}

extension TextEditViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
     return 1
   }

    func collectionView(
     _ collectionView: UICollectionView,
     numberOfItemsInSection section: Int
   ) -> Int {
       return textEditMenuItems.count
   }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let menuItem = textEditMenuItems[indexPath.row]

        let cell = collectionView.dequeueReusableCell(
           withReuseIdentifier: textEditMenuItemReuseIdentifier,
           for: indexPath
        ) as! TextEditMenuItemCVCell

        cell.label.text = menuItem.identifier.rawValue
        cell.layer.cornerRadius = 6
        cell.layer.borderWidth = 2
        
        if menuItem.selected {
            cell.imageView.image = menuItem.selectedImage
            cell.layer.borderColor = UIColor.white.cgColor
//            cell.backgroundColor = .white
//            cell.imageView.tintColor = .black
//            cell.label.textColor = . black
        }
        else {
            cell.imageView.image = menuItem.normalImage
            cell.layer.borderColor = UIColor.clear.cgColor

//            cell.backgroundColor = .clear
//            cell.imageView.tintColor = .white
//            cell.label.textColor = . white
        }

     return cell
   }
}

extension TextEditViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
      _ collectionView: UICollectionView,
      layout collectionViewLayout: UICollectionViewLayout,
      sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
      // 2
        let heightPaddingSpace = sectionInsets.top * 2
        let availableHeight = collectionView.frame.height - heightPaddingSpace
        let availabelWidth = collectionView.frame.width - (sectionInsets.left * CGFloat(textEditMenuItems.count + 1))
        let itemWidth = floor(availabelWidth / CGFloat(textEditMenuItems.count))
        
        return CGSize(width: max(minimumItemWidth, itemWidth), height: availableHeight)
    
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
