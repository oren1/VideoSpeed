//
//  EditViewController+UndoRedo.swift
//  VideoSpeed
//

import UIKit
import CoreMedia

extension EditViewController {
    func startObservingProjectHistoryDiff() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(projectHistoryDiffDidChange(_:)),
            name: .ProjectHistoryDiffDidChange,
            object: nil
        )
    }

    @objc private func projectHistoryDiffDidChange(_ notification: Notification) {
        guard let diff = notification.userInfo?[ProjectHistoryDiffNotification.diffKey] as? ProjectHistoryDiff else {
            return
        }
        Task { @MainActor in
            await handleProjectHistoryDiff(diff)
        }
    }

    func handleProjectHistoryDiff(_ diff: ProjectHistoryDiff) async {
        print(diff)
       
        await self.reloadComposition()
        let startTime = self.getStartTimeForCurrentSpidAsset()
        await self.spidPlayerController?.player?.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        self.spidPlayerController?.player.play()
        
       
        
        for (assetId, changes) in diff.updatedAssets {
            for change in changes {
                switch change {
                case .speed(let speed):
                     /* 1. show a simple alert message for 1 second with the type of change and the value
                     2. reload the videos collectionView and apply a flickering effect on the updated asset.
                     the current 'assetId'
                     3. if the UserDataManager.currentSpidAsset is the asset that was changed('assetId') then call
                     'spidSectionVC.currentSpidAssetDidChange' */
                    
                    print("speed: \(speed)")
                default:
                    print("default")

                }
            }

        }
        
       
    }
}
