//
//  EditViewController+BottomMenu.swift
//  VideoSpeed
//
//  Created by oren shalev on 26/01/2025.
//

import Foundation
import UIKit

extension EditViewController: UICollectionViewDataSource {
     func numberOfSections(in collectionView: UICollectionView) -> Int {
      return 1
    }

     func collectionView(
      _ collectionView: UICollectionView,
      numberOfItemsInSection section: Int
    ) -> Int {
        return self.menuItems.count
    }

     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      
     let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: menuItemReuseIdentifier,
        for: indexPath
      ) as! MenuItemCell

      
      let item = menuItems[indexPath.row]
      cell.titleLabel.text = item.title
      cell.layer.cornerRadius = 8

      return cell
    }
}

extension EditViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let menuItem = menuItems[indexPath.row]
        
        if menuItem.id != .crop {
            removeCropVCFromTop()
        }
        
        currentShownSection.remove()
        
        switch menuItem.id {
        case .speed:
            addSpeedSection()
        case .trim:
            addTrimmerSection()
        case .crop:
            addCropSection()
            addCropViewControllerToTop()
        case .fps:
            addFPSSection()
        case .sound:
            addSoundSection()
        case .more:
            addFiletypeSection()
            
        }
    }
}

extension EditViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
      _ collectionView: UICollectionView,
      layout collectionViewLayout: UICollectionViewLayout,
      sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
      // 2
//      let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
//      let availableWidth = view.frame.width - paddingSpace
//      let widthPerItem = floor(availableWidth / itemsPerRow)
      return CGSize(width: 60, height: 54)
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
