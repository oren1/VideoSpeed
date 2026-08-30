//
//  EditViewController+UndoRedo.swift
//  VideoSpeed
//

import UIKit
import SwiftUI
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
            await flickerAsset(assetID: assetId)

            for change in changes {
                switch change {
                case .speed(let speed):
                    showBriefChangeAlert(type: "speed", value: "\(speed)")
                    if await UserDataManager.main.currentSpidAsset?.id == assetId {
                        speedSectionVC.currentSpidAssetDidChange()
                    }
                case .timeRange(let cmTimeRange):
                    guard let asset = await UserDataManager.main.spidAsset(for: assetId) else { break }
                    if await asset.isImageClip {
                        showBriefChangeAlert(type: "duration", value: String(format: "%.1f", cmTimeRange.duration.seconds))
                        if await UserDataManager.main.currentSpidAsset?.id == assetId {
                            imageDurationSectionVC.currentSpidAssetDidChange()
                        }
                    } else {
                        showBriefChangeAlert(type: "Trim", value: "")
                        if await UserDataManager.main.currentSpidAsset?.id == assetId {
                            trimmerSectionVC.currentSpidAssetDidChange()
                        }
                    }
                   
                default:
                    print("default")
                }
            }
        }
        
        /* 1. loop trough the diff.insertedAssetIds
           2. if there's an asset there, then either an asset was splitted or a new asset was added
           so we need to update the in-memory UserDataManager.spidAssets and add that asset to the array
           3. reder the changes to the UI showing the additional asset */
    }

    private func showBriefChangeAlert(type: String, value: String) {
        let message = value.isEmpty ? type : "\(type): \(value)"
        let rootView = ZStack {
            BriefChangeAlertView(
                message: message,
                size: CGSize(width: 180, height: 56)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)

        let hostingVC = UIHostingController(rootView: rootView)
        hostingVC.modalPresentationStyle = .overFullScreen
        hostingVC.view.backgroundColor = .clear

        present(hostingVC, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak hostingVC] in
            hostingVC?.dismiss(animated: false)
        }
    }

    private func flickerAsset(assetID: UUID) async {

        guard let index = await UserDataManager.main.assetIndex(for: assetID) else { return }
        let indexPath = IndexPath(item: index, section: 0)
        guard let cell = videosCollectionView.cellForItem(at: indexPath) else { return }

        cell.alpha = 1
        await UIView.animateKeyframes(withDuration: 0.6, delay: 0, options: []) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.25) {
                cell.alpha = 0.2
            }
            UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25) {
                cell.alpha = 1
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.25) {
                cell.alpha = 0.2
            }
            UIView.addKeyframe(withRelativeStartTime: 0.75, relativeDuration: 0.25) {
                cell.alpha = 1
            }
        }
    }
}
