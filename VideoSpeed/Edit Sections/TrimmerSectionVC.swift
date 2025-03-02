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
}

// added an extension to give the 'playerViewController' variable a default implementation.
extension TrimmerViewSpidDelegate {
    var spidPlayerController: SpidPlayerViewController! {
        get { nil }
    }
}

typealias TimeRangeClosure = (_ timeRange: CMTimeRange) -> Void

class TrimmerSectionVC: SectionViewController {
    
    weak var delegate: TrimmerViewSpidDelegate!
    @IBOutlet weak var trimmerView: TrimmerView!
    var playbackTimeCheckerTimer: Timer?
    var timeRangeDidChange: TimeRangeClosure?
    var playerItem: AVPlayerItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            trimmerView.asset = await UserDataManager.main.currentSpidAsset.getAsset()
            trimmerView.delegate = self
            trimmerView.handleColor = UIColor.white
            trimmerView.mainColor = UIColor.systemBlue
            trimmerView.maskColor = UIColor.black
            trimmerView.positionBarColor = UIColor.clear
            trimmerView.regenerateThumbnails()
            // 1. create a new PlayerItem with the original video asset
            let originalAsset = await UserDataManager.main.currentSpidAsset.getOriginalAsset()
            playerItem = AVPlayerItem(asset: originalAsset)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
        
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        timeRangeDidChange?(timeRange)
    }

    func didChangePositionBar(_ playerTime: CMTime) {
        Task {
            await MainActor.run {
                delegate?.spidPlayerController?.player?.pause()
            }
            // 2. Set the playerController's player with the new PlayerItem
            delegate?.spidPlayerController?.player?.replaceCurrentItem(with: playerItem!)
            await delegate?.spidPlayerController?.player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
        
    }
    
}
