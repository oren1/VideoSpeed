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
        /* Updating whether at least one 'SpidAsset' is using the slider.
         i.e it's speed value is different from 0.25, 0.5, 1, 1.5 or 2 */
        UserDataManager.main.usingSlider = await UserDataManager.main.isUsingSliderPrecision()
        await self.reloadComposition()
        let startTime = self.getStartTimeForCurrentSpidAsset()
        await self.spidPlayerController?.player?.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        self.spidPlayerController?.player.play()
        await self.textSectionVC.createTrimmerView()
        
        speedSectionVC.currentSpidAssetDidChange()
    }
}
