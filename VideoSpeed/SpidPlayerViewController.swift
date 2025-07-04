//
//  SpidPlayerViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 07/01/2025.
//

import UIKit
import AVFoundation
import Combine
import SwiftUI


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
    private(set) var videoState = VideoState.isPaused
    let timeFormatter = DateComponentsFormatter()
    var videoDuration = 0.0
    
    var panGestureRecognizer: UIPanGestureRecognizer!
    var tapGestureRecognizer: UITapGestureRecognizer!
    var pinchGestureRecognizer: UIPinchGestureRecognizer!
    var rotationGestureRecognizer: UIRotationGestureRecognizer!
    var testLabel: SpidLabel!
    var secondLabel: SpidLabel!
    var selectedLabel: SpidLabel!
    var labels: [SpidLabel] = []
    var cancellable: AnyCancellable!
    var textOverlayLabelsCancellable: AnyCancellable!
    var overlayLabelViewsCancellabel: AnyCancellable!
    var labelViewModelsCancellabel: AnyCancellable!
    var labelViews: [LabelView] = []
    var selectedLabelView: LabelView?
    var scaleValue = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoContainerView = UIView(frame: CGRectZero)
        mainContainer.insertSubview(videoContainerView, belowSubview: timeContainerView)
        timeContainerView?.layer.cornerRadius = 4
        setTimeFormatter()
        setGestureRecognizers()
                
        NotificationCenter.default.addObserver(forName: Notification.Name.OverlayLabelViewsUpdated , object: nil, queue: nil) { [weak self] notification in
            self?.addLabelViews(labelViewsModels: UserDataManager.main.labelViewsModels)
        }
        
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

    deinit {
        cancellable = nil
        textOverlayLabelsCancellable = nil
        overlayLabelViewsCancellabel = nil
        labelViewModelsCancellabel = nil
        NotificationCenter.default.removeObserver(self)
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
            videoContainerView.clipsToBounds = true
            playerLayer.frame = videoContainerView.bounds
           
            player.play()

            startPlaybackTimeChecker()
            
        }
        
    }
    
    func addLabelViews(labelViews: [LabelView]) {
        for (index, labelView) in labelViews.enumerated() {
           
            labelView.gestureRecognizers?.removeAll()
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView(_:)))
            labelView.addGestureRecognizer(tapGestureRecognizer)
            
            self.videoContainerView.addSubview(labelView)
            
            if labelView.viewModel.center == .zero && labelViews.count - 1 == index  {
                labelView.viewModel.center = CGPoint(x: videoContainerView.frame.width / 2, y: videoContainerView.frame.height / 2)
               
                UserDataManager.main.setSelectedLabeViewModel(labelView.viewModel)
//                UserDataManager.main.setSelectedLabeView(labelView)
            }
        
        }
    }
    
    func addLabelViews(labelViewsModels: [LabelViewModel]) {
        // Remove all LabelView's from the screen
        for view in videoContainerView.subviews {
            if view is LabelView {
                view.removeFromSuperview()
            }
        }
        for (index, viewModel) in labelViewsModels.enumerated() {
           // Create a new LabelView for every viewModel and add it to the screen
            let labelView = LabelView.instantiateWithViewModel(viewModel)
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView(_:)))
            labelView.addGestureRecognizer(tapGestureRecognizer)
            
            if labelView.viewModel.center == .zero && labelViewsModels.count - 1 == index  {
                labelView.viewModel.center = CGPoint(x: videoContainerView.frame.width / 2, y: videoContainerView.frame.height / 2)
               
                UserDataManager.main.setSelectedLabeViewModel(labelView.viewModel)
            }
            
            let scale = viewModel.fullScale
            let rotation = viewModel.fullRotation
            

            self.videoContainerView.addSubview(labelView)
            
            labelView.transform = labelView.transform.scaledBy(x: scale, y: scale)
            labelView.transform = labelView.transform.rotated(by: rotation)
        }
        
    }
    
   
    
    func setSelectedLabelView(labelView: LabelView) {
        
        UserDataManager.main.selectedLabelView?.viewModel.selected = false
        
        labelView.viewModel.selected = true
        UserDataManager.main.selectedLabelView = labelView
        
    }
    
    @objc func didTapView(_ gesture: UITapGestureRecognizer) {
        guard let labelView = gesture.view as? LabelView else {
          return
        }
       
        UserDataManager.main.setSelectedLabeViewModel(labelView.viewModel)
//        UserDataManager.main.setSelectedLabeView(labelView)
//        setSelectedLabelView(labelView: labelView)
    }
    
    @objc func didRotate(_ gesture: UIRotationGestureRecognizer) {

        guard let selectedLabelViewModel = UserDataManager.main.selectedLabelViewModel else {return}
//        selectedLabelView.transform = selectedLabelView.transform.rotated(
//          by: gesture.rotation
//        )
//        fullRotation += gesture.rotation
        selectedLabelViewModel.rotation = gesture.rotation
        selectedLabelViewModel.fullRotation += gesture.rotation
//        selectedLabelView.viewModel.updateRotation(rotation: gesture.rotation)
        gesture.rotation = 0
    
    }
    
    @objc func didPinch(_ gesture: UIPinchGestureRecognizer) {

        guard let selectedLabelViewModel = UserDataManager.main.selectedLabelViewModel else {return}

        selectedLabelViewModel.scale = gesture.scale
        selectedLabelViewModel.width *= gesture.scale
        selectedLabelViewModel.height *= gesture.scale
        
        gesture.scale = 1
    }
    
    
    
    @objc func didPanLabel(_ gesture: UIPanGestureRecognizer) {
         let translation = gesture.translation(in: self.videoContainerView)
        
        guard let selectedLabelViewModel = UserDataManager.main.selectedLabelViewModel else { return }
          let center = CGPoint(
            x: selectedLabelViewModel.center.x + translation.x,
            y: selectedLabelViewModel.center.y + translation.y
          )
          selectedLabelViewModel.center = center
          gesture.setTranslation(.zero, in: view)
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
    
    
    // MARK: Custom Logic
    func getCATextLayers() -> [CATextLayer] {
        let textLayers =  labels.map { label in
            let textLayer = CATextLayer()
            textLayer.string = label.text
            textLayer.shouldRasterize = true
            textLayer.rasterizationScale = 2
            textLayer.backgroundColor = UIColor.green.cgColor
            textLayer.alignmentMode = .center
            return textLayer
        }
        return textLayers
    }
    
    func setGestureRecognizers() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPanLabel(_:)))
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView(_:)))
        pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
        
        view.addGestureRecognizer(panGestureRecognizer)
        view.addGestureRecognizer(pinchGestureRecognizer)
        view.addGestureRecognizer(rotationGestureRecognizer)
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
            await updateLabelViews()
            let currentTime = player.currentTime()
            
            await updateSliderFor(time: currentTime)
            
        }
        
    }
    
    func updateSliderFor(time: CMTime) async {
        let sliderValue = await getSliderValue(time.seconds)

        await MainActor.run {
            slider.value = sliderValue
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
        guard  let videoDuration = try? await playerLayer.player!.currentItem!.asset.load(.duration).seconds else { return }

        let formattedVideoCurrentTimeString = timeFormatter.string(from: TimeInterval(ceill(videoCurrentTime)))
        let formattedVideoDurationString =  timeFormatter.string(from: TimeInterval(videoDuration))
        
        await MainActor.run {
            timeLabel.text = formattedVideoCurrentTimeString
            durationLabel.text = "/ " + formattedVideoDurationString!
        }
    }
    
    
    func getTime(_ sliderValue: Float) async -> CMTime {
        
        guard  let videoDuration = try? await playerLayer.player!.currentItem!.asset.load(.duration).seconds else { return .zero }
        let seconds = videoDuration * Double(sliderValue) * 600

        return CMTime(value: CMTimeValue(seconds), timescale: 600)
    }
    
    func getSliderValue(_ currentTime: TimeInterval) async -> Float {
        guard  let videoDuration = try? await playerLayer.player!.currentItem!.asset.load(.duration).seconds else { return 0 }
        return Float(1/videoDuration * currentTime)
    }
    
    func updateLabelViews() async {
        let videoCurrentTime =  playerLayer.player!.currentTime()

        for labelViewModel in UserDataManager.main.labelViewsModels {
            
            if let timeRange = labelViewModel.timeRange {
                if timeRange.containsTime(videoCurrentTime) {
                    labelViewModel.isHidden = false
                    continue
                }
                labelViewModel.isHidden = true

            }
            else {
                labelViewModel.isHidden = false
            }
            
        }
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
//            await MainActor.run(body: { [weak self] in self?.player.pause()})
            player.pause()
            await player.seek(to: currentTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            await updateTimeLabels()
            await updateLabelViews()
        }
    }
    
    
    @objc func xButtonTapped(sender: UIButton) {
        print("xButtonTapped")
    }
    
}
