//
//  TrimmerSectionVC.swift
//  VideoSpeed
//
//  Created by oren shalev on 20/12/2024.
//

import UIKit
import AVFoundation
import AVKit

protocol TrimmerViewSpidDelegate: AnyObject {
    var spidPlayerController: SpidPlayerViewController! { get set }
    func getCurrentFrameImage() async -> UIImage?
}

// added an extension to give the 'playerViewController' variable a default implementation.
extension TrimmerViewSpidDelegate {
    var spidPlayerController: SpidPlayerViewController! {
        get { nil }
    }
}

typealias TimeRangeClosure = (_ timeRange: CMTimeRange) -> Void

fileprivate let trimmerHeight = 60.0

class TrimmerSectionVC: SectionViewController {
    
    weak var delegate: TrimmerViewSpidDelegate!
    @IBOutlet weak var trimmerView: TrimmerView!
    var playbackTimeCheckerTimer: Timer?
    var timeRangeDidChange: TimeRangeClosure?
    var playerItem: AVPlayerItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(videoSelectionChanged), name: Notification.Name.VideoSelectionChanged, object: nil)
        
        trimmerView.delegate = self
        trimmerView.handleColor = UIColor.white
        trimmerView.mainColor = UIColor.systemBlue
        trimmerView.maskColor = UIColor.black
        trimmerView.positionBarColor = UIColor.clear

        Task {
            await reloadTrimmer()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task {
            await reloadTrimmer()
        }
    }

    @objc private func videoSelectionChanged() {
        Task {
            await reloadTrimmer()
        }
    }

    @MainActor
    func reloadTrimmer() async {
        guard let spidAsset = UserDataManager.main.currentSpidAsset else { return }

        let clipAsset = await spidAsset.getAsset()
        let selectionRange = await spidAsset.timeRange
        let clipSourceRange = await spidAsset.clipSourceRange
        let originalAsset = await spidAsset.getOriginalAsset()
        playerItem = AVPlayerItem(asset: originalAsset)

        trimmerView.clipTimeRange = clipSourceRange
        trimmerView.asset = clipAsset
        trimmerView.assetPreview.contentOffset = .zero

        let applyHandles: () -> Void = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.applyHandlePositions(
                    for: spidAsset,
                    selectionRange: selectionRange,
                    clipSourceRange: clipSourceRange
                )
            }
        }

        if let thumbnailImages = await spidAsset.thumbnailImages {
            trimmerView.replaceTo(thumbnailImages: thumbnailImages)
            applyHandles()
        } else {
            trimmerView.generateClipThumbnails(for: clipSourceRange, trimmerHeight: trimmerHeight) { images in
                Task {
                    await UserDataManager.main.currentSpidAsset?.updateThumbnailImages(images: images)
                }
                applyHandles()
            }
        }
    }

    @MainActor
    private func applyHandlePositions(
        for spidAsset: SpidAsset,
        selectionRange: CMTimeRange,
        clipSourceRange: CMTimeRange
    ) async {
        if let rightConstraintConstant = await spidAsset.rightHandleConstraintConstant,
           let leftConstraintConstant = await spidAsset.leftHandleConstraintConstant {
            trimmerView.updateLeftConstraint(constatnt: leftConstraintConstant)
            trimmerView.updateRightConstraint(constatnt: rightConstraintConstant)
        } else if CMTimeRangeEqual(selectionRange, clipSourceRange) {
            trimmerView.resetHandlesToFullClip()
        } else {
            trimmerView.applySelectionRange(selectionRange, clipBounds: clipSourceRange)
        }
    }
    
    func startPlaybackTimeChecker() {

        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self,
                                                        selector:
            #selector(onPlaybackTimeChecker), userInfo: nil, repeats: true)
    }

    func stopPlaybackTimeChecker() {

        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }
    
    @objc func onPlaybackTimeChecker() {

        guard let startTime = trimmerView.startTime,
              let endTime = trimmerView.endTime,
              let player = delegate?.spidPlayerController?.player else {
            return
        }

        let playBackTime = player.currentTime()
        trimmerView.seek(to: playBackTime)

        if playBackTime >= endTime {
            player.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            trimmerView.seek(to: startTime)
        }
    }
    
}

extension TrimmerSectionVC: TrimmerViewDelegate {
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        delegate?.spidPlayerController?.player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        delegate?.spidPlayerController?.player?.play()
        
        guard let startTime = trimmerView.startTime, let endTime = trimmerView.endTime else {return}
        Task { @MainActor in
            let timeRange = CMTimeRange(start: startTime, end: endTime)
            let currentSpidAsset = UserDataManager.main.currentSpidAsset
            await currentSpidAsset?.updateRightHandleConstraintConstant(constant: trimmerView.rightConstraint!.constant)
            await currentSpidAsset?.updateLeftHandleConstraintConstant(constant: trimmerView.leftConstraint!.constant)
            timeRangeDidChange?(timeRange)
        }
    }

    func didChangePositionBar(_ playerTime: CMTime) {
        Task {
            await MainActor.run {
                delegate?.spidPlayerController?.player?.pause()
            }
            delegate?.spidPlayerController?.player?.replaceCurrentItem(with: playerItem)
            await delegate?.spidPlayerController?.player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
        
    }
    
}
