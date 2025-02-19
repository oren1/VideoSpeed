//
//  TextSectionVCViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 29/01/2025.
//

import UIKit
import AVFoundation
import Combine

class TextSectionVC: SectionViewController {
    
    @IBOutlet weak var textCollectionView: UICollectionView!
    @IBOutlet weak var trimmerView: TrimmerView!
    
    let textCellReusableIdentifier = "TextCell"
    let plusCellIReusableIdentifier = "PlusCell"
    let cellWidth = 84.0
    private var sectionInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    private var cancellable: AnyCancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let textCellNib = UINib(nibName: "TextCell", bundle: nil)
        let plusCellNib = UINib(nibName: "PlusCell", bundle: nil)
    
        textCollectionView.register(textCellNib, forCellWithReuseIdentifier: textCellReusableIdentifier)
        textCollectionView.register(plusCellNib, forCellWithReuseIdentifier: plusCellIReusableIdentifier)
        textCollectionView.dataSource = self
        textCollectionView.delegate = self
        
        cancellable = UserDataManager.main.$overlayLabelViews.sink(receiveValue: { [weak self] labelViews in
            self?.textCollectionView.reloadData()
        })
        
        Task {
            await createTrimmerView()
        }
        
       
    }
    
    deinit {
        cancellable = nil
        print("removed cancellable ref")
    }

    @MainActor
    func createTrimmerView() async {
        trimmerView.asset = await UserDataManager.main.currentSpidAsset.getAsset()
        trimmerView.delegate = self
        trimmerView.handleColor = UIColor.white
        trimmerView.mainColor = UIColor.systemBlue
        trimmerView.maskColor = UIColor.black
        trimmerView.positionBarColor = UIColor.clear
        trimmerView.regenerateThumbnails()
        trimmerView.isUserInteractionEnabled = false
        trimmerView.layer.opacity = 0.4
    }
    
}


typealias CollectionView = TextSectionVC
extension CollectionView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
   
    // MARK: Datasource
   func numberOfSections(in collectionView: UICollectionView) -> Int {
     return 1
   }

    func collectionView(
     _ collectionView: UICollectionView,
     numberOfItemsInSection section: Int
   ) -> Int {
       return UserDataManager.main.overlayLabelViews.count + 1
   }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == UserDataManager.main.overlayLabelViews.count {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: plusCellIReusableIdentifier,
               for: indexPath
            ) as! PlusCell
            
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: textCellReusableIdentifier,
        for: indexPath
        ) as! TextCell

         
         let labelView = UserDataManager.main.overlayLabelViews[indexPath.row]
         cell.textLabel.text = labelView.viewModel.text
         cell.layer.cornerRadius = 8

         return cell
   }
    
    // MARK: Delegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Selection of the plus button
        if indexPath.row == UserDataManager.main.overlayLabelViews.count {
            // open the TextEditViewController
            
            if let navigationController = view.window?.rootViewController as? UINavigationController {
                let textEditViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TextEditViewController") as! TextEditViewController
                textEditViewController.modalPresentationStyle = .fullScreen
                navigationController.present(textEditViewController, animated: true)
            }
            return
        }
        
        let label = UserDataManager.main.overlayLabelViews[indexPath.row]
        
    }
    
    func collectionView(
      _ collectionView: UICollectionView,
      layout collectionViewLayout: UICollectionViewLayout,
      sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
      // 2
        let overlayLabelViews = UserDataManager.main.overlayLabelViews
        let heightPaddingSpace = sectionInsets.top * 2
        let availableHeight = collectionView.frame.height - heightPaddingSpace
//        let availabelWidth = collectionView.frame.width - widthPaddingSpace
        
        return CGSize(width: cellWidth, height: availableHeight)
    
    }

    // 3
    func collectionView(
      _ collectionView: UICollectionView,
      layout collectionViewLayout: UICollectionViewLayout,
      insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        let numberOfCells = UserDataManager.main.overlayLabelViews.count + 1
        let totalCellWidth = (cellWidth * Double(numberOfCells))
        let totalSpacingWidth = sectionInsets.left * Double(numberOfCells - 1)

        let leftInset = (collectionView.frame.size.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
        let rightInset = leftInset

        if leftInset < sectionInsets.left {
            return sectionInsets
        }
        
        return UIEdgeInsets(top: sectionInsets.top, left: leftInset, bottom: sectionInsets.bottom, right: rightInset)

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

typealias Trimmer = TextSectionVC
extension Trimmer: TrimmerViewDelegate {
    func positionBarStoppedMoving(_ playerTime: CMTime) {
       
    }

    func didChangePositionBar(_ playerTime: CMTime) {
        
    }
    
}
