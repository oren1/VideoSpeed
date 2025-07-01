//
//  EditViewController+VideosMenu.swift
//  VideoSpeed
//
//  Created by oren shalev on 26/06/2025.
//

import Foundation
import UIKit

typealias VideoSelectionClosure = (SpidAsset) -> Void

class VideosMenuDelegate: NSObject {
    
    var didSelectVideo: VideoSelectionClosure?
    
    override init() {
        super.init()
    }
    private(set) var sectionInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    fileprivate let minimumItemWidth = 64.0

}


extension VideosMenuDelegate: UICollectionViewDataSource {
     func numberOfSections(in collectionView: UICollectionView) -> Int {
      return 1
    }

     func collectionView(
      _ collectionView: UICollectionView,
      numberOfItemsInSection section: Int
    ) -> Int {
        return UserDataManager.main.spidAssets.count
    }

     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      
     let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: "VideoItemCVCell",
        for: indexPath
      ) as! VideoItemCVCell

      
      let spidAsset = UserDataManager.main.spidAssets[indexPath.row]
         if spidAsset === UserDataManager.main.currentSpidAsset {
             cell.layer.borderColor = UIColor.white.cgColor
             cell.layer.borderWidth = 2
         }
         else {
             cell.layer.borderWidth = 0
         }
        cell.imageView.image = UIImage(cgImage: spidAsset.thumbnailImage)

      return cell
    }
}

extension VideosMenuDelegate: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let spidAsset = UserDataManager.main.spidAssets[indexPath.row]
        UserDataManager.main.currentSpidAsset = spidAsset
        collectionView.reloadData()
        didSelectVideo?(spidAsset)
    }
}

extension VideosMenuDelegate: UICollectionViewDelegateFlowLayout {

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
        let heightPaddingSpace = sectionInsets.top * 2
        let availableHeight = collectionView.frame.height - heightPaddingSpace
        let cellWidth = availableHeight
        let numberOfItems = CGFloat(UserDataManager.main.spidAssets.count)
        let numberOfSeperators = numberOfItems - 1
        let contentWidth = (cellWidth * numberOfItems) + (sectionInsets.left * numberOfSeperators)
        if contentWidth > collectionView.frame.width {
            return sectionInsets
        }
        else {
            let horizontalPadding = (collectionView.frame.width - contentWidth) / 2
            let sectionInsets = UIEdgeInsets(top: 2, left: horizontalPadding, bottom: 2, right: horizontalPadding)
            return sectionInsets
        }
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


class VideoItemCVCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
}
