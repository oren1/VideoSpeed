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
    private var videoState = VideoState.isPaused
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
        
        overlayLabelViewsCancellabel = UserDataManager.main.$overlayLabelViews.sink(receiveValue: { [weak self] labelViews in
            self?.addLabelViews(labelViews: labelViews)
        })
        
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
        for labelView in labelViews {
            
            labelView.gestureRecognizers?.removeAll()
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView(_:)))
            labelView.addGestureRecognizer(tapGestureRecognizer)
            
            self.videoContainerView.addSubview(labelView)
            
            if labelView.center == .zero {
                labelView.center = CGPoint(x: videoContainerView.frame.width / 2, y: videoContainerView.frame.height / 2)
                selectedLabelView = labelView
            }

        }
    }
    
    func addLabelViewsFor(moodels: [LabelViewModel]) {
        //1. Iterate trough the modelViews array and remove all of them from the view and delete the array
        for labelView in labelViews {
            labelView.removeFromSuperview()
        }
        labelViews.removeAll()
        
        //2. Add them again with the updated models
        for model in moodels {
            
            let labelView = LabelView.instantiateWithLabelViewModel(model)
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView(_:)))
            labelView.addGestureRecognizer(tapGestureRecognizer)
            
            labelViews.append(labelView)
            self.videoContainerView.addSubview(labelView)
            
            if labelView.center == .zero { // This means it's a newly created labelViewModel
                labelView.center = CGPoint(x: videoContainerView.frame.width / 2, y: videoContainerView.frame.height / 2)
                setSelectedLabelView(labelView: labelView)

            }

        }
    }
    
    func addLabels(_ textOverlayLabels: [SpidLabel]) {
        
        for (index, spidLabel) in textOverlayLabels.enumerated() {
            self.videoContainerView.addSubview(spidLabel)
            
            if spidLabel.center == .zero {
                spidLabel.center = CGPoint(x: videoContainerView.frame.width / 2, y: videoContainerView.frame.height / 2)
            }
            
            

            if index == (textOverlayLabels.count - 1) {
                setSelectedLabel(spidLabel: spidLabel)
            }
            

        }
        
//        let testString = "This is a test label string"
//
//        let testLabelFrame = testString.textSize(withConstrainedWidth: videoContainerView.frame.size.width, font: .boldSystemFont(ofSize: 17))
//        testLabel = SpidLabel(frame: testLabelFrame)
////        testLabel.backgroundColor = .darkGray
//        testLabel.textColor = .white
////        testLabel.attributedText = attributedQuote
//        testLabel.numberOfLines = 0
//        testLabel.font = UIFont.boldSystemFont(ofSize: 17)
//        testLabel.text = testString
//        testLabel.backgroundColor = .black
//        self.videoContainerView.addSubview(testLabel)
//        testLabel.center = CGPoint(x: self.videoContainerView.frame.width / 2, y: self.videoContainerView.frame.height / 2)
//        testLabel.isUserInteractionEnabled = true
//
//        secondLabel = SpidLabel(frame: CGRect(origin: CGPointZero, size: CGSize(width: 100, height: 21)))
////        secondLabel.backgroundColor = .black
//        secondLabel.textColor = .white
//        secondLabel.text = "This is a test"
//        self.videoContainerView.addSubview(secondLabel)
////        secondLabel.center = CGPoint(x: self.videoContainerView.frame.width / 2, y: self.videoContainerView.frame.height / 2)
//        secondLabel.isUserInteractionEnabled = true
//       
//        let secondTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView(_:)))
//        
//        testLabel.addGestureRecognizer(tapGestureRecognizer)
//        secondLabel.addGestureRecognizer(secondTapGestureRecognizer)
//        labels.append(contentsOf: [testLabel, secondLabel])
//        UserDataManager.main.textOverlayLabels.append(contentsOf: [testLabel, secondLabel])
    }
    
    func setSelectedLabel(spidLabel: SpidLabel)  {
        selectedLabel?.layer.borderWidth = 0
        
        spidLabel.layer.borderColor = UIColor.orange.cgColor
        spidLabel.layer.borderWidth = 1
        
        selectedLabel = spidLabel
    }
    
    func setSelectedLabelView(labelView: LabelView) {
        selectedLabelView?.layer.borderWidth = 0
        selectedLabelView?.cancelButton.isHidden = true
        
        labelView.layer.borderColor = UIColor.orange.cgColor
        labelView.layer.borderWidth = 1
        labelView.cancelButton.isHidden = false
        
        selectedLabelView = labelView
    }
    
    @objc func didTapView(_ gesture: UITapGestureRecognizer) {
        guard let labelView = gesture.view as? LabelView else {
          return
        }
       
        setSelectedLabelView(labelView: labelView)
    }
    
    @objc func didRotate(_ gesture: UIRotationGestureRecognizer) {

        guard let selectedLabelView = self.selectedLabelView else {return}
        selectedLabelView.transform = selectedLabelView.transform.rotated(
          by: gesture.rotation
        )
        
        selectedLabelView.viewModel.updateRotation(rotation: gesture.rotation)
        gesture.rotation = 0
    
    }
    
    @objc func didPinch(_ gesture: UIPinchGestureRecognizer) {

        guard let selectedLabelView = self.selectedLabelView else {return}
        selectedLabelView.transform = selectedLabelView.transform.scaledBy(
          x: gesture.scale,
          y: gesture.scale
        )
        
        selectedLabelView.viewModel.width *= gesture.scale
        selectedLabelView.viewModel.height *= gesture.scale

        gesture.scale = 1
    }
    
    
    
    @objc func didPanLabel(_ gesture: UIPanGestureRecognizer) {
         let translation = gesture.translation(in: self.videoContainerView)
        
          guard let selectedLabelView = self.selectedLabelView else { return }
          let center = CGPoint(
            x: selectedLabelView.center.x + translation.x,
            y: selectedLabelView.center.y + translation.y
          )
          selectedLabelView.center = center
          
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
            let currentTime = player.currentTime().seconds
//            print("current time: \(currentTime)")
            let sliderValue = await getSliderValue(currentTime)

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
