//
//  TextSectionVCViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 29/01/2025.
//

import UIKit

class TextSectionVC: SectionViewController {
    
    @IBOutlet weak var textCollectionView: UICollectionView!
    let textCellReusableIdentifier = "TextCell"
    let plusFooterReusableIdentifier = "PlusFooterReusableView"
    let footerViewWidth = 94.0
    private var sectionInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

    override func viewDidLoad() {
        super.viewDidLoad()

        let textCellNib = UINib(nibName: "TextCell", bundle: nil)
        let plusFooterNib = UINib(nibName: "PlusFooterReusableView", bundle: nil)
    
        textCollectionView.register(textCellNib, forCellWithReuseIdentifier: textCellReusableIdentifier)
        textCollectionView.register(plusFooterNib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: plusFooterReusableIdentifier)
        textCollectionView.dataSource = self
        textCollectionView.delegate = self

    }

}


extension TextSectionVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
   
    // MARK: Datasource
   func numberOfSections(in collectionView: UICollectionView) -> Int {
     return 1
   }

    func collectionView(
     _ collectionView: UICollectionView,
     numberOfItemsInSection section: Int
   ) -> Int {
       return 0
   }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
     
    let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: textCellReusableIdentifier,
       for: indexPath
    ) as! TextCell

     
     let label = UserDataManager.main.textOverlayLabels[indexPath.row]
     cell.textLabel.text = label.text
     cell.layer.cornerRadius = 8

     return cell
   }
 
    func collectionView(
      _ collectionView: UICollectionView,
      viewForSupplementaryElementOfKind kind: String,
      at indexPath: IndexPath
    ) -> UICollectionReusableView {
      switch kind {
      // 1
      case UICollectionView.elementKindSectionFooter:
        // 2
        let footerView = collectionView.dequeueReusableSupplementaryView(
          ofKind: kind,
          withReuseIdentifier: plusFooterReusableIdentifier,
          for: indexPath)

        // 3
          guard let plusFooterView = footerView as? PlusFooterReusableView
          else { return footerView }
          let heightPaddingSpace = sectionInsets.top * 2
          let availableHeight = collectionView.frame.height - heightPaddingSpace
          plusFooterView.frame = CGRect(origin: CGPointZero, size: CGSize(width: 150, height: availableHeight))

        // 4
        return plusFooterView
      default:
          let footerView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: plusFooterReusableIdentifier,
            for: indexPath)
          footerView.frame = CGRectZero
          return footerView
      }
    }
    
    // MARK: Delegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let label = UserDataManager.main.textOverlayLabels[indexPath.row]
        
    }
    
    func collectionView(
      _ collectionView: UICollectionView,
      layout collectionViewLayout: UICollectionViewLayout,
      sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
      // 2
        let textOverlayLabels = UserDataManager.main.textOverlayLabels
        let heightPaddingSpace = sectionInsets.top * 2
        let widthPaddingSpace = sectionInsets.left * CGFloat(textOverlayLabels.count + 1)
        let availableHeight = collectionView.frame.height - heightPaddingSpace
//        let availabelWidth = collectionView.frame.width - widthPaddingSpace
        
        return CGSize(width: 84, height: availableHeight)
    
    }

    // 3
    func collectionView(
      _ collectionView: UICollectionView,
      layout collectionViewLayout: UICollectionViewLayout,
      insetForSectionAt section: Int
    ) -> UIEdgeInsets {
//        let totalCellWidth = CellWidth * CellCount
//        let totalSpacingWidth = CellSpacing * (CellCount - 1)
//
//        let leftInset = (collectionViewWidth - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
//        let rightInset = leftInset
//
//        return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
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
