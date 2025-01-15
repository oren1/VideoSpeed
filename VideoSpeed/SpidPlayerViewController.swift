//
//  SpidPlayerViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 07/01/2025.
//

import UIKit
import AVFoundation
import Combine

enum VideoState: Int {
    case isPlayed = 0, isPaused
}

class SpidPlayerViewController: UIViewController {
    
    
    @IBOutlet weak var mainContainer: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var timeContainerView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var slider: UISlider!
    
    var videoContainerView: UIView!
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var aspectRatio: CGFloat = 3/4
    var playbackTimeCheckerTimer: Timer?
    private var videoState = VideoState.isPaused
    let timeFormatter = DateComponentsFormatter()
    var videoDuration = 0.0
    var cancellable: Cancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        videoContainerView = UIView(frame: CGRectZero)
        mainContainer.insertSubview(videoContainerView, belowSubview: timeContainerView)
        timeContainerView?.layer.cornerRadius = 4
        setTimeFormatter()
        
        
        slider.setThumbImage(UIImage(), for: .normal)
               slider.setThumbImage(UIImage(), for: .highlighted)
        
        cancellable = player?.publisher(for: \.timeControlStatus).sink(receiveValue: { timeControlStatus in
            switch timeControlStatus {
            case .paused:
                self.stopPlaybackTimeChecker()
                self.videoState = .isPaused
                self.playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            case .playing:
                self.startPlaybackTimeChecker()
                self.videoState = .isPlayed
                self.playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            default:
                return
            }
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlaybackTimeChecker()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        Task {
            if playerLayer == nil {
                let videoSize = await UserDataManager.main.currentSpidAsset.videoSize
                playerLayer = AVPlayerLayer(player: player)
                aspectRatio = videoSize.width / videoSize.height
            }
            
            videoDuration = await UserDataManager.main.currentSpidAsset.videoDuration()

            playerLayer.backgroundColor = UIColor.black.cgColor
            videoContainerView.frame = videoContainerRect()
            videoContainerView.center = CGPointMake(mainContainer.frame.width / 2, mainContainer.frame.height / 2)
            videoContainerView.layer.addSublayer(playerLayer)
            playerLayer.frame = videoContainerView.bounds
           
            player.play()

            startPlaybackTimeChecker()
            
            addLabels()
        }
    
    }
    
    func addLabels() {
        let testLabel = UILabel(frame: CGRect(origin: CGPointZero, size: CGSize(width: 100, height: 50)))
        testLabel.backgroundColor = .darkGray
        testLabel.textColor = .white
        testLabel.text = "This is a test"
        self.videoContainerView.addSubview(testLabel)
        testLabel.center = CGPoint(x: self.videoContainerView.frame.width / 2, y: self.videoContainerView.frame.height / 2)
    }
    
    func videoContainerRect() -> CGRect{
        let height: Double
        let width: Double
        
        if  aspectRatio < 1 { // portrait video
             height = mainContainer.frame.size.height
             width = height * aspectRatio
        }
        else if aspectRatio > 1 { // landscape video
            width = mainContainer.frame.size.width
             height = width / aspectRatio
        }
        else { // square
             height = mainContainer.frame.size.height
             width = mainContainer.frame.size.width
        }
        
        return CGRectMake(0, 0, width, height)
    }
    
    
    
    
    // MARK: Playback Cheker
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
        
        Task {
            await updateTimeLabels()
            let currentTime = player.currentTime().seconds
//            print("current time: \(currentTime)")
            let sliderValue = await getSliderValue(currentTime)
            print("sliderValue: \(sliderValue)")

            await MainActor.run {
                slider.value = sliderValue
            }
            
        }
        
    }
    
    
    // MARK: Custom Logic
    func setTimeFormatter() {
        timeFormatter.allowedUnits = [.minute, .second]
        timeFormatter.unitsStyle = .positional
        timeFormatter.zeroFormattingBehavior = .pad
        timeFormatter.allowsFractionalUnits = true
    }
    
    func updateTimeLabels() async {
        let videoCurrentTime =  playerLayer.player!.currentTime().seconds
        
        let videoDuration = await UserDataManager.main.currentSpidAsset.videoDuration()

        let formattedVideoCurrentTimeString = timeFormatter.string(from: TimeInterval(ceill(videoCurrentTime)))
        let formattedVideoDurationString =  timeFormatter.string(from: TimeInterval(videoDuration))
        
        await MainActor.run {
            timeLabel.text = formattedVideoCurrentTimeString
            durationLabel.text = "/ " + formattedVideoDurationString!
        }
    }
    
    
    func getTime(_ sliderValue: Float) async -> CMTime {
        let videoDuration = await UserDataManager.main.currentSpidAsset.videoDuration()
        let seconds = videoDuration * Double(sliderValue) * 600

        return CMTime(value: CMTimeValue(seconds), timescale: 600)
    }
    
    func getSliderValue(_ currentTime: TimeInterval) async -> Float {
        let videoDuration = await UserDataManager.main.currentSpidAsset.videoDuration()
        return Float(1/videoDuration * currentTime)
    }
    
    
    
    // MARK: Actions
    @IBAction func playButtonTapped(_ sender: Any) {
        if videoState == .isPlayed {
            player.pause()
        }
        else if videoState == .isPaused {
            player.play()
        }
    }
    
    @IBAction func sliderValueChanged(_ slider: UISlider) {
        Task {
            let currentTime = await getTime(slider.value)
            await MainActor.run(body: { [weak self] in self?.player.pause()})
            player.pause()
            await player.seek(to: currentTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            await updateTimeLabels()
        }
    }
    
    
}
