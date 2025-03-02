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
    
    weak var delegate: TrimmerViewSpidDelegate!

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
        
        NotificationCenter.default.addObserver(forName: Notification.Name.OverlayLabelViewsUpdated , object: nil, queue: nil) { [weak self] notification in
            
            self?.setTrimmerInteractionStatus()
            self?.textCollectionView.reloadData()
        }

        NotificationCenter.default.addObserver(forName: Notification.Name.SelectedLabelViewChanged , object: nil, queue: nil) { [weak self] notification in
            self?.updateTrimmerViewHandles()
            self?.textCollectionView.reloadData()
        }
        
        Task {
            await createTrimmerView()
        }
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    deinit {
        cancellable = nil
        print("removed cancellable ref")
    }

    @MainActor
    func createTrimmerView() async {
        trimmerView.asset = self.delegate.spidPlayerController?.player.currentItem?.asset != nil ? self.delegate.spidPlayerController.player.currentItem?.asset :
        await UserDataManager.main.currentSpidAsset.getAsset()
        
        trimmerView.delegate = self
        trimmerView.handleColor = UIColor.white
        trimmerView.mainColor = UIColor.systemBlue
        trimmerView.maskColor = UIColor.black
        trimmerView.positionBarColor = UIColor.clear
        trimmerView.regenerateThumbnails()
        setTrimmerInteractionStatus()
    }
    
    func updateTrimmerViewHandles() {
        guard let viewModel = UserDataManager.main.selectedLabelView?.viewModel else {
            return
        }
        self.trimmerView.updateRightConstraint(constatnt: viewModel.rightHandleConstraintConstant ??  0)
        self.trimmerView.updateLeftConstraint(constatnt: viewModel.leftHandleConstraintConstant ?? 0)
    }
    
    func setTrimmerInteractionStatus() {
        if UserDataManager.main.overlayLabelViews.count > 0 {
            self.enableTrimmerView()
        }
        else {
            self.disableTrimmerView()
        }
    }
    
    func enableTrimmerView() {
        trimmerView.isUserInteractionEnabled = true
        trimmerView.layer.opacity = 1
    }
    
    func disableTrimmerView() {
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
         if labelView.viewModel.selected {
             cell.backgroundColor = .systemBlue
         }
         else {
             cell.backgroundColor = .gray
         }
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

        
        let selectedLabelView = UserDataManager.main.overlayLabelViews[indexPath.row]
        UserDataManager.main.setSelectedLabeView(selectedLabelView)
        
        collectionView.reloadData()
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
        delegate?.spidPlayerController?.player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        delegate?.spidPlayerController?.player?.play()
        
        guard let startTime = trimmerView.startTime, let endTime = trimmerView.endTime else {return}
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        if let viewModel = UserDataManager.main.selectedLabelView?.viewModel {
            viewModel.timeRange = timeRange
            viewModel.rightHandleConstraintConstant = trimmerView.rightConstraint?.constant
            viewModel.leftHandleConstraintConstant = trimmerView.leftConstraint?.constant
        }
    }

    func didChangePositionBar(_ playerTime: CMTime) {
        Task {
            await MainActor.run {
                delegate?.spidPlayerController?.player?.pause()
            }
            
            await delegate?.spidPlayerController?.player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
        
    }
    
}
