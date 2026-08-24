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
        
       
        
        for (assetId, fields) in diff.updatedAssets {
           var speedOrSliderChanged = false
           var timeRangeChanged = false
            
            if fields.contains(.speed) || fields.contains(.sliderValue) {
                speedOrSliderChanged = true
            }
            if fields.contains(.timeRange) {
                timeRangeChanged = true
            }
            
            let assetIndex = await UserDataManager.main.assetIndex(for: assetId)!
            
            if speedOrSliderChanged {
               
            }
            
            if timeRangeChanged {
            
            }
            

            break

        }
        
       
    }
}
