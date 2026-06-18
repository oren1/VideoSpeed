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
    
    weak var collectionView: UICollectionView?
    weak var trashDropView: UIView?
    
    var didSelectVideo: VideoSelectionClosure?
    var itemDidDrop: ((Int) -> Void)?
    var itemDidDelete: ((Int, Bool) -> Void)?
    var canDeleteItems: (() -> Bool)?
    var setTrashDragState: ((_ isDragging: Bool, _ isHovering: Bool) -> Void)?
    var selectedMenuItem: MenuItem!
    
    override init() {
        super.init()
    }
    private(set) var sectionInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    fileprivate let minimumItemWidth = 64.0
    
    private var isClipDragActive = false
    
    private func isDragOverTrash(_ session: UIDropSession) -> Bool {
        guard let trashDropView else { return false }
        return trashDropView.bounds.contains(session.location(in: trashDropView))
    }
    
    private func updateTrashAppearance(hovering: Bool = false) {
        setTrashDragState?(isClipDragActive, hovering)
    }
    
    private func beginClipDrag() {
        isClipDragActive = true
        updateTrashAppearance()
    }
    
    private func endClipDrag() {
        isClipDragActive = false
        updateTrashAppearance()
    }
    
    private func deleteVideo(spidAsset: SpidAsset) {
        guard canDeleteItems?() ?? false,
              let collectionView,
              let index = UserDataManager.main.spidAssets.firstIndex(where: { $0 === spidAsset }),
              UserDataManager.main.spidAssets.count > 1 else { return }
        
        let wasCurrent = spidAsset === UserDataManager.main.currentSpidAsset
        UserDataManager.main.spidAssets.remove(at: index)
        
        let focusIndex: Int
        if wasCurrent {
            focusIndex = min(index, UserDataManager.main.spidAssets.count - 1)
            UserDataManager.main.currentSpidAsset = UserDataManager.main.spidAssets[focusIndex]
        } else {
            focusIndex = min(index, UserDataManager.main.spidAssets.count - 1)
        }
        
        collectionView.performBatchUpdates {
            collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        endClipDrag()
        itemDidDelete?(focusIndex, wasCurrent)
    }

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
         if spidAsset === UserDataManager.main.currentSpidAsset &&
                selectedMenuItem.id != .fps &&
                selectedMenuItem.id != .more &&
                selectedMenuItem.id != .text {
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


extension VideosMenuDelegate: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    // MARK: - Drag Delegate
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard UserDataManager.main.spidAssets.count > 1 else { return [] }
        beginClipDrag()
        let spidAsset = UserDataManager.main.spidAssets[indexPath.row]
        let itemProvider = NSItemProvider()
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = spidAsset
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession, at indexPath: IndexPath) {
        beginClipDrag()
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        UIView.animate(withDuration: 0.2) {
            cell.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        endClipDrag()
        collectionView.visibleCells.forEach { cell in
            UIView.animate(withDuration: 0.2) {
                cell.transform = .identity
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if isDragOverTrash(session) {
            updateTrashAppearance(hovering: canDeleteItems?() ?? false)
            return UICollectionViewDropProposal(operation: .cancel)
        }
        updateTrashAppearance(hovering: false)
        
        if session.localDragSession != nil {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
        }
    }

    // MARK: - Drop Delegate
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }

        coordinator.items.forEach { dropItem in
            if let sourceIndexPath = dropItem.sourceIndexPath,
               let spidAsset = dropItem.dragItem.localObject as? SpidAsset {
                UserDataManager.main.spidAssets.remove(at: sourceIndexPath.item)
                UserDataManager.main.spidAssets.insert(spidAsset, at: destinationIndexPath.item)
                
                collectionView.performBatchUpdates {
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndexPath])
                }
                coordinator.drop(dropItem.dragItem, toItemAt: destinationIndexPath)
                itemDidDrop?(destinationIndexPath.row)
            }
        }
    }
}

extension VideosMenuDelegate: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        guard session.localDragSession != nil else { return false }
        return session.items.contains { $0.localObject is SpidAsset }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        if canDeleteItems?() ?? false {
            updateTrashAppearance(hovering: true)
            return UIDropProposal(operation: .move)
        }
        updateTrashAppearance(hovering: false)
        return UIDropProposal(operation: .forbidden)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard let dragItem = session.items.first,
              let spidAsset = dragItem.localObject as? SpidAsset else { return }
        deleteVideo(spidAsset: spidAsset)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        updateTrashAppearance(hovering: false)
    }
}


class VideoItemCVCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
}
