//
//  EditViewController+BottomMenu.swift
//  VideoSpeed
//
//  Created by oren shalev on 26/01/2025.
//

import Foundation
import UIKit

fileprivate let minimumItemWidth = 64.0

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
      if item == selectedMenuItem {
          cell.backgroundColor = .white
          cell.imageView.tintColor = .black
          cell.titleLabel.textColor = .black
      }
      else {
          cell.backgroundColor = UIColor(red: 0.093, green: 0.093, blue: 0.093, alpha: 1)
          cell.titleLabel.textColor = .white
          cell.imageView.tintColor = .white
      }
      
      cell.layer.cornerRadius = 8

         
      cell.titleLabel.text = item.title
      cell.imageView.image = UIImage(systemName: item.imageName)

      return cell
    }
}

extension EditViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let menuItem = menuItems[indexPath.row]
        selectedMenuItem = menuItem
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
        case .text:
            addTextSection()
        case .more:
            addFiletypeSection()
            
        }
        
        collectionView.reloadData()
    }
}

extension EditViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
      _ collectionView: UICollectionView,
      layout collectionViewLayout: UICollectionViewLayout,
      sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
      // 2
        let heightPaddingSpace = sectionInsets.top * 2
        let availableHeight = collectionView.frame.height - heightPaddingSpace
        let availabelWidth = collectionView.frame.width - (sectionInsets.left * CGFloat(menuItems.count + 1))
        let itemWidth = floor(availabelWidth / CGFloat(menuItems.count))
        
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
