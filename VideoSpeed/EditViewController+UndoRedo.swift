//
//  EditViewController+UndoRedo.swift
//  VideoSpeed
//

import UIKit
import SwiftUI
import CoreMedia

extension EditViewController {
    func startObservingUndoManagerChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(undoManagerDidChangeField(_:)),
            name: .UndoManagerDidChangeField,
            object: nil
        )
    }

    @objc private func undoManagerDidChangeField(_ notification: Notification) {
        guard let undoField = notification.userInfo?[UndoManagerNotification.fieldKey] as? UndoField else {
            return
        }
        Task { @MainActor in
            switch undoField {
            case .speed(let speed, let spidAsset):
                let assetId = spidAsset.id
                await flickerAsset(assetID: assetId)
                showBriefChangeAlert(type: "speed", value: "\(speed)")
                if UserDataManager.main.currentSpidAsset == spidAsset {
                    speedSectionVC.currentSpidAssetDidChange()
                }
            case .timeRange(let cmTimeRange, let spidAsset):
                let assetId = spidAsset.id
                await flickerAsset(assetID: assetId)
                if await spidAsset.mediaKind == .video {
                    showBriefChangeAlert(type: "trim", value: "")
                    if UserDataManager.main.currentSpidAsset == spidAsset {
                        trimmerSectionVC.currentSpidAssetDidChange()
                    }
                }
                else {
                    showBriefChangeAlert(type: "duration", value: "\(cmTimeRange.duration.seconds)")
                    if UserDataManager.main.currentSpidAsset == spidAsset {
                        imageDurationSectionVC.currentSpidAssetDidChange()
                    }
                }
            case .videoFilter(let filterName, let spidAsset):
                await flickerAsset(assetID: spidAsset.id)
                let displayName = VideoFilter(rawValue: filterName)?.displayName ?? filterName
                showBriefChangeAlert(type: "filter", value: displayName)
                if UserDataManager.main.currentSpidAsset == spidAsset {
                    await filterSectionVC.reloadFromCurrentAsset()
                }
                await reloadComposition()
            case .split(let snapshot):
                showBriefChangeAlert(type: "split", value: "")

                videosCollectionView.reloadData()
                updateTrashVisibility()
                await reloadComposition()
                notifyCurrentSpidAssetDidChange()
                await splitSectionVC.reloadTimelineFromOutside()

            case .labels:
                showBriefChangeAlert(type: "text", value: "")
                // `labelViewsModels` didSet already posts OverlayLabelViewsUpdated;
                // TextSectionVC / SpidPlayer refresh from that notification.

            case .captions:
                showBriefChangeAlert(type: "captions", value: "")
                // Restoring transcription/style/pose triggers SpidPlayer rebuild via publishers.

            case .fps(let fps):
                self.fps = fps
                self.fpsLabel.text = "\(fps):fps"
                fpsSectionVC.syncUI(to: fps)
                showProButtonIfNeeded()
                showBriefChangeAlert(type: "fps", value: "\(fps)")
                await reloadComposition()

            case .soundOn(let soundOn, let spidAsset):
                await flickerAsset(assetID: spidAsset.id)
                showBriefChangeAlert(type: "sound", value: soundOn ? "on" : "off")
                if UserDataManager.main.currentSpidAsset == spidAsset {
                    self.soundOn = soundOn
                    let imageName = soundOn ? "volume.2.fill" : "volume.slash"
                    soundButton.setImage(UIImage(systemName: imageName), for: .normal)
                    soundSectionVC.updateSoundSelection(soundOn: soundOn)
                }
                UserDataManager.main.soundOff = await UserDataManager.main.soundOff()
                showProButtonIfNeeded()
                await reloadComposition()

            case .audio:
                showBriefChangeAlert(type: "audio", value: "")
                await reloadComposition()
                audioSectionVC.configure(
                    track: UserDataManager.main.backgroundAudioTrack,
                    compositionDuration: composition?.duration ?? .zero,
                    timelineAsset: spidPlayerController?.player?.currentItem?.asset
                )

            default:
                print("undoManagerDidChangeFielddefault")
            }
            
//            await SwiftDataManager.shared.upsertVideoProject()
        }
        
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
