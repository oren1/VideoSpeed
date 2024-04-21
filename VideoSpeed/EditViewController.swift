//
//  ViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 13/07/2023.
//

import UIKit
import AVFoundation
import AVKit
import FirebaseRemoteConfig

class EditViewController: UIViewController {
    var playerController: AVPlayerViewController!
    var asset: AVAsset!
    var composition: AVMutableComposition!
    var videoComposition: AVMutableVideoComposition!
    var speed: Float = 1
    var fps: Int32 = 30
    var fileType: AVFileType = .mov
    var soundOn: Bool! = true
    var assetUrl: URL!
    var compositionOriginalDuration: CMTime!
    var compositionVideoTrack: AVMutableCompositionTrack!
    var exportSession: AVAssetExportSession?
    var timer: Timer?
    var proButton: UIButton!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    lazy var progressIndicatorView: ProgressIndicatorView = {
        progressIndicatorView = ProgressIndicatorView()
        return progressIndicatorView
    }()
    
    lazy var blackTransparentOverlay: BlackTransparentOverlay = {
        blackTransparentOverlay = BlackTransparentOverlay()
        return blackTransparentOverlay
    }()
    
    lazy var usingProFeaturesAlertView: UsingProFeaturesAlertView = {
        usingProFeaturesAlertView = UsingProFeaturesAlertView()
        return usingProFeaturesAlertView
    }()
    
    // Bottom tabs
    @IBOutlet weak var speedButton: UIButton!
    @IBOutlet weak var fpsButton: UIButton!
    @IBOutlet weak var fileTypeButton: UIButton!
    var selectedBottomButton: UIButton!

    
    // Navigation right item labels
    var speedLabel: UILabel!
    var fpsLabel: UILabel!
    var fileTypeLabel: UILabel!
    var soundImageView: UIImageView!
    var soundButton: UIButton!
    
    
    // Sections
    var speedSectionVC: SpeedSectionVC!
    var fpsSectionVC: FPSSectionVC!
    var soundSectionVC: SoundSectionVC!
    var moreSectionVC: MoreSectionVC!
    
    @IBOutlet weak var dashboardContainerView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(usingSliderChanged), name: Notification.Name("usingSliderChanged"), object: nil)
        
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black, .font: UIFont.boldSystemFont(ofSize: 17)], for: .selected)
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white,
                                                 .font: UIFont.boldSystemFont(ofSize: 17)], for: .normal)
        
        setNavigationItems()
        proButton = createProButton()
        addSpeedSection()
        addFPSSection()
        addSoundSection()
        addFiletypeSection()

        showSpeedSection()
        
        asset = AVAsset(url: assetUrl)
        Task {
            guard let (composition, videoComposition) = await createCompositionWith(speed: speed, fps: fps, soundOn: soundOn) else {
                return showNoTracksError()
            }
            self.composition = composition
            self.videoComposition = videoComposition
            
            let compositionCopy = self.composition.copy() as! AVComposition
            let videoCompositionCopy = self.videoComposition.copy() as! AVVideoComposition

            let playerItem = AVPlayerItem(asset: compositionCopy)
            playerItem.audioTimePitchAlgorithm = .spectral
            playerItem.videoComposition = videoCompositionCopy
            
            let player = AVPlayer(playerItem: playerItem)
        
            playerController = AVPlayerViewController()
            playerController.player = player
            addPlayerToTop()
            loopVideo()
            
        }

        
    }

    deinit {
        UserDataManager.main.usingSlider = false
    }
    
    func createProButton() -> UIButton {
        let proButton = UIButton(type: .roundedRect)
        proButton.tintColor = .systemBlue
        proButton.backgroundColor = .white
        proButton.setTitle("Pro Version", for: .normal)
        proButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        proButton.addTarget(self, action: #selector(proButtonTapped), for: .touchUpInside)
        proButton.layer.cornerRadius = 8
        proButton.layer.borderWidth = 1
        proButton.layer.borderColor = UIColor.lightGray.cgColor
        return proButton
    }
    
    func createCompositionWith(speed: Float, fps: Int32, soundOn: Bool) async -> (composition: AVMutableComposition, videoComposition: AVMutableVideoComposition)? {
        let composition = AVMutableComposition(urlAssetInitializationOptions: nil)

        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: 1)!
        
        if let audioTracks = try? await asset.loadTracks(withMediaType: .audio),
           soundOn && audioTracks.count > 0 {
            let audioTrack = audioTracks[0]
            let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: 2)!
            let audioDuration = try! await asset.load(.duration)
            
            try? compositionAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: audioDuration),
                                                                    of: audioTrack,
                                                                    at: CMTime.invalid)

        }
        
        
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first,
              let videoDuration = try? await asset.load(.duration),
              let naturalSize = try? await videoTrack.load(.naturalSize),
              let preferredTransform = try? await videoTrack.load(.preferredTransform) else {return nil}

                
        try? compositionVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoDuration),
                                                                of: videoTrack,
                                                                at: CMTime.invalid)
        
        
       
        
        guard let compositionOriginalDuration = try? await composition.load(.duration) else {return nil}
        self.compositionOriginalDuration = compositionOriginalDuration
        let newDuration = Int64(compositionOriginalDuration.seconds / Double(speed))
        composition.scaleTimeRange(CMTimeRange(start: .zero, duration: compositionOriginalDuration), toDuration: CMTime(value: newDuration, timescale: 1))
        
        
        compositionVideoTrack.preferredTransform = preferredTransform

        let videoInfo = VideoHelper.orientation(from: preferredTransform)
        print("videoInfo.orientation \(videoInfo.orientation)")

        let videoSize: CGSize

        if videoInfo.isPortrait {
          videoSize = CGSize(
            width: naturalSize.height,
            height: naturalSize.width)
        } else {
          videoSize = naturalSize
        }
        
        print("videoSize \(videoSize)")

        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(
          start: .zero,
          duration: composition.duration)
        
        let layerInstruction = await compositionLayerInstruction(
          for: compositionVideoTrack,
          assetTrack: videoTrack,
          videoSize: videoSize,
          isPortrait: videoInfo.isPortrait)
        
        instruction.layerInstructions = [layerInstruction]
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [instruction]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: fps)
        videoComposition.renderSize = videoSize


        return (composition,videoComposition)
        
    }
    
    
    func reloadComposition() async {
        guard let (composition, videoComposition) = await createCompositionWith(speed: speed, fps: fps, soundOn: soundOn) else {
            return showNoTracksError()
        }
        self.composition = composition
        self.videoComposition = videoComposition
        let compositionCopy = self.composition.copy() as! AVComposition
        let videoCompositionCopy = self.videoComposition.copy() as! AVVideoComposition

        let playerItem = AVPlayerItem(asset: compositionCopy)
        playerItem.audioTimePitchAlgorithm = .spectral
        playerItem.videoComposition = videoCompositionCopy

        playerController.player?.replaceCurrentItem(with: playerItem)
    }
    
    
    
    func setNavigationItems() {
        let exportButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(tryToExportVideo))
        
        speedLabel = createRightItemLabel()
        speedLabel.text = "\(speed)x"

        fpsLabel = createRightItemLabel()
        fpsLabel.text = "\(fps):FPS"

        fileTypeLabel = createRightItemLabel()
        fileTypeLabel.text = fileType == .mov ? "MOV" : "MP4"
        
        soundImageView = UIImageView(image: UIImage(systemName: "volume.2.fill"))
        soundImageView.tintColor = .white
        
        soundButton = UIButton(type: .system)
        soundButton.tintColor = .white
        soundButton.setImage(UIImage(systemName: "volume.2.fill"), for: .normal)
        soundButton.addTarget(self, action: #selector(soundButtonTapped), for: .touchUpInside)
        
        let speedItem = UIBarButtonItem(customView: speedLabel)
        let fpsItem = UIBarButtonItem(customView: fpsLabel)
        let fileTypeItem = UIBarButtonItem(customView: fileTypeLabel)
        let soundItem = UIBarButtonItem(customView: soundButton)

        
        navigationItem.rightBarButtonItems = [exportButton, soundItem, fileTypeItem, fpsItem, speedItem]
    }
    
    @objc func soundButtonTapped() {
       
            guard let purchasedProduct = SpidProducts.store.userPurchasedProVersion() else {
                
                    soundOn = !soundOn
                    let imageName = soundOn ? "volume.2.fill" : "volume.slash"
                    soundButton.setImage(UIImage(systemName: imageName), for: .normal)
                    soundSectionVC.updateSoundSelection(soundOn: soundOn)
                    showProButtonIfNeeded()
                    Task {
                        await self.reloadComposition()
                    }
                
                    return
            }
        
            soundOn = !soundOn
            let imageName = soundOn ? "volume.2.fill" : "volume.slash"
            soundButton.setImage(UIImage(systemName: imageName), for: .normal)
            soundSectionVC.updateSoundSelection(soundOn: soundOn)
            
            Task {
                await self.reloadComposition()
            }
        
    }
    
    func createRightItemLabel() -> UILabel {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        label.layer.cornerRadius = 8
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
        return label
    }
    
    
    @objc func tryToExportVideo() {
            guard let _ = SpidProducts.store.userPurchasedProVersion() else {
                if !usingProFeatures() {
                    self.playerController.player?.pause()
                  return InterstitialAd.manager.showAd(controller: self) { [weak self] in
                        self?.playerController.player?.play()
                        self?.exportVideo()
                    }
                    
                }
                else {
                    // show alert for purchase
                    showProFeatureAlert()
                    return
                }
            }
        
            exportVideo()
    }
    
    @objc func exportVideo() {
        let theComposition = composition.copy() as! AVComposition
        let videoComposition = videoComposition.copy() as! AVVideoComposition
        
        guard let exportSession = AVAssetExportSession(
          asset: theComposition,
          presetName: AVAssetExportPresetHighestQuality)
          else {
            print("Cannot create export session.")
            return
        }
        
        self.exportSession = nil
        self.exportSession = exportSession
        
        let fileExtension = fileType == .mov ? "mov" : "mp4"
        let videoName = UUID().uuidString
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
          .appendingPathComponent(videoName)
          .appendingPathExtension(fileExtension)
        
        exportSession.videoComposition = videoComposition
        exportSession.outputFileType = fileType
        exportSession.outputURL = exportURL
        
        showProgreeView()
        exportSession.exportAsynchronously {
            DispatchQueue.main.async { [weak self] in
              guard let self = self else { return  }
              self.removeProgressView()
              switch exportSession.status {
              case .completed:
                print("completed export with url: \(exportURL)")
                  guard UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(exportURL.relativePath) else { return }
                   
                   // 3
                  UISaveVideoAtPathToSavedPhotosAlbum(exportURL.relativePath, self, #selector(self.video(_:didFinishSavingWithError:contextInfo:)),nil)
                  
              default:
                print("Something went wrong during export.")
                print(exportSession.error ?? "unknown error")
                break
              }
            }

        }
        
    }
    
    @objc func video(
      _ videoPath: String,
      didFinishSavingWithError error: Error?,
      contextInfo info: AnyObject
    ) {
        if error == nil {
            let successMessageViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SuccessMessageViewController") as! SuccessMessageViewController
            if UIDevice.current.userInterfaceIdiom == .phone {
                successMessageViewController.modalPresentationStyle = .fullScreen
            }
            self.present(successMessageViewController, animated: true)
        }
        else {
            let alert = UIAlertController(
              title: "Error",
              message: "Video failed to save",
              preferredStyle: .alert)
            alert.addAction(UIAlertAction(
              title: "OK",
              style: UIAlertAction.Style.cancel,
              handler: nil))
            present(alert, animated: true, completion: nil)
        }

    }
    
    func addPlayerToTop() {
        //add as a childviewcontroller
        addChild(playerController)

         // Add the child's View as a subview
         self.view.addSubview(playerController.view)

        playerController.view.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            playerController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            playerController.view.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor),
            playerController.view.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor),
            playerController.view.bottomAnchor.constraint(equalTo: self.dashboardContainerView.topAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
        
         // tell the childviewcontroller it's contained in it's parent
        playerController.didMove(toParent: self)
        self.playerController.player?.play()
    }

    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack, videoSize: CGSize, isPortrait: Bool) async -> AVMutableVideoCompositionLayerInstruction {

        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let transform = try! await assetTrack.load(.preferredTransform)
        if isPortrait {
            var newTransform = CGAffineTransform(translationX: 0, y: 0)
            newTransform = newTransform.rotated(by: CGFloat(90 * Double.pi / 180))
            newTransform = newTransform.translatedBy(x: 0, y: -videoSize.width)
            instruction.setTransform(newTransform, at: .zero)
        }
        else {
            instruction.setTransform(transform, at: .zero)
        }

        return instruction
    }
    
    
    // MARK: - Actions
    @IBAction func segmentedValueChanged(_ segmentedControl: UISegmentedControl) {
        let currentIndex = segmentedControl.selectedSegmentIndex
        switch currentIndex {
        case 0:
            showSpeedSection()
        case 1:
            showFPSSection()
        case 2:
            showSoundSection()
        default:
            showFileTypeSection()
        }
    }
    
    // MARK: - Sections Logic
    func showProButton() {
        self.view.addSubview(proButton)
        proButton.translatesAutoresizingMaskIntoConstraints = false

        let constraints = [
            proButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            proButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            proButton.widthAnchor.constraint(equalToConstant: 100),
            proButton.heightAnchor.constraint(equalToConstant: 34)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    func hideProButton() {
        proButton.removeFromSuperview()
    }
    
    func addSpeedSection() {
        speedSectionVC = SpeedSectionVC()
        
        speedSectionVC.sliderValueChange = { [weak self] (speed: Float) -> () in
            self?.speedLabel.text = "\(speed)x"
        }
        
        speedSectionVC.speedDidChange = { [weak self] (speed: Float) -> () in
            self?.speed = speed
            self?.speedLabel.text = "\(speed)x"

            Task {
              await self?.reloadComposition()
            }
        }
        
        speedSectionVC.userNeedsToPurchase = { [weak self] in
            self?.showPurchaseViewController()
            self?.speed = 1
            self?.speedLabel.text = "1x"
            Task {
              await self?.reloadComposition()
            }
        }
        
        addSection(sectionVC: speedSectionVC)
    }
    
    func addFPSSection() {
        fpsSectionVC = FPSSectionVC()
        fpsSectionVC.fpsDidChange = {[weak self] (fps: Int32) in
            guard let self = self else {return}
            self.fps = fps
            self.fpsLabel.text = "\(fps):fps"
            showProButtonIfNeeded()
            Task {
                await self.reloadComposition()
            }
        }
        fpsSectionVC.userNeedsToPurchase = {[weak self] in
            self?.showPurchaseViewController()
        }
        addSection(sectionVC: fpsSectionVC)
    }
    
    func addSoundSection()  {
        soundSectionVC = SoundSectionVC()
        soundSectionVC.soundStateChanged = {[weak self] (soundOn: Bool) in
            self?.soundOn = soundOn
            let imageName = soundOn ? "volume.2.fill" : "volume.slash"
            self?.soundButton.setImage(UIImage(systemName: imageName), for: .normal)
            self?.showProButtonIfNeeded()
            Task {
              await self?.reloadComposition()
            }
        }
        soundSectionVC.userNeedsToPurchase = {[weak self] in
            self?.showPurchaseViewController()
        }
        addSection(sectionVC: soundSectionVC)
    }
    
    func addFiletypeSection() {
        moreSectionVC = MoreSectionVC()
        moreSectionVC.fileTypeDidChange = {[weak self] (fileType: AVFileType) in
            self?.fileType = fileType
            self?.fileTypeLabel.text = fileType == .mov ? "MOV" : "MP4"
            self?.showProButtonIfNeeded()
        }
        moreSectionVC.soundStateChanged = {[weak self] (soundOn: Bool) in
            self?.soundOn = soundOn
            let imageName = soundOn ? "volume.2.fill" : "volume.slash"
            self?.soundButton.setImage(UIImage(systemName: imageName), for: .normal) 
            self?.showProButtonIfNeeded()
            Task {
              await self?.reloadComposition()
            }
        }
        moreSectionVC.userNeedsToPurchase = {[weak self] in
            self?.showPurchaseViewController()
        }
        addSection(sectionVC: moreSectionVC)
    }
    
    func addSection(sectionVC: SectionViewController) {
        addChild(sectionVC)
        dashboardContainerView.addSubview(sectionVC.view)
        sectionVC.view.translatesAutoresizingMaskIntoConstraints = false

        let constraints = [
            sectionVC.view.topAnchor.constraint(equalTo: dashboardContainerView.topAnchor),
            sectionVC.view.leftAnchor.constraint(equalTo: dashboardContainerView.leftAnchor),
            sectionVC.view.rightAnchor.constraint(equalTo: dashboardContainerView.rightAnchor),
            sectionVC.view.bottomAnchor.constraint(equalTo: dashboardContainerView.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
        
        sectionVC.didMove(toParent: self)
    }
    
    
    func showSpeedSection() {
        speedSectionVC.view.isHidden = false
        fpsSectionVC.view.isHidden = true
        soundSectionVC.view.isHidden = true
        moreSectionVC.view.isHidden = true
    }

    func showFPSSection() {
        speedSectionVC.view.isHidden = true
        fpsSectionVC.view.isHidden = false
        soundSectionVC.view.isHidden = true
        moreSectionVC.view.isHidden = true
    }
    
    func showSoundSection() {
        speedSectionVC.view.isHidden = true
        fpsSectionVC.view.isHidden = true
        soundSectionVC.view.isHidden = false
        moreSectionVC.view.isHidden = true
    }
    
    func showFileTypeSection() {
        speedSectionVC.view.isHidden = true
        fpsSectionVC.view.isHidden = true
        soundSectionVC.view.isHidden = true
        moreSectionVC.view.isHidden = false
    }
    
    func showProgreeView() {
        view.addSubview(progressIndicatorView)
        progressIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        let constraints = [
            progressIndicatorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressIndicatorView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            progressIndicatorView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            progressIndicatorView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
        progressIndicatorView.progressView.progress = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let progress = self?.exportSession?.progress else { return }
            self?.progressIndicatorView.progressView.progress = progress
        }

    }
    
    func removeProgressView() {
        timer?.invalidate()
        timer = nil
        progressIndicatorView.removeFromSuperview()
    }
    
    
    // MARK: - UI Logic
    func showBlackTransparentOverlay() {
        self.navigationController!.view.addSubview(blackTransparentOverlay)
        blackTransparentOverlay.translatesAutoresizingMaskIntoConstraints = false

        let constraints = [
            blackTransparentOverlay.topAnchor.constraint(equalTo: navigationController!.view.topAnchor),
            blackTransparentOverlay.leftAnchor.constraint(equalTo: navigationController!.view.leftAnchor),
            blackTransparentOverlay.rightAnchor.constraint(equalTo: navigationController!.view.rightAnchor),
            blackTransparentOverlay.bottomAnchor.constraint(equalTo: navigationController!.view.bottomAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func hideBlackTransparentOverlay() {
        blackTransparentOverlay.removeFromSuperview()
    }
    
    func showUsingProFeaturesAlertView() {
        usingProFeaturesAlertView.updateStatus(usingSlider: UserDataManager.main.usingSlider,
                                               soundOn: soundOn,
                                               fps: fps,
                                               fileType: fileType)
        usingProFeaturesAlertView.layer.opacity = 0
        self.navigationController!.view.addSubview(usingProFeaturesAlertView)
        usingProFeaturesAlertView.translatesAutoresizingMaskIntoConstraints = false
        usingProFeaturesAlertView.onCancel = { [weak self] in
            self?.hideProFeatureAlert()
        }
        usingProFeaturesAlertView.onContinue = { [weak self] in
            self?.showPurchaseViewController()
            self?.hideProFeatureAlert()
        }
        let constraints = [
            usingProFeaturesAlertView.heightAnchor.constraint(equalToConstant: 300),
            usingProFeaturesAlertView.widthAnchor.constraint(equalToConstant: 340),
            usingProFeaturesAlertView.centerXAnchor.constraint(equalTo: navigationController!.view.safeAreaLayoutGuide.centerXAnchor),
            usingProFeaturesAlertView.centerYAnchor.constraint(equalTo: navigationController!.view.safeAreaLayoutGuide.centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.usingProFeaturesAlertView.layer.opacity = 1
        }
        
    }
    func hideUsingProFeaturesAlertView() {
        usingProFeaturesAlertView.removeFromSuperview()
    }
    
    func showProFeatureAlert() {
        showBlackTransparentOverlay()
        showUsingProFeaturesAlertView()
    }
    
    func hideProFeatureAlert() {
        self.hideBlackTransparentOverlay()
        self.hideUsingProFeaturesAlertView()
    }
    
    // MARK: - Custom Logic
    func showPurchaseViewController() {
        let businessModelRawValue = RemoteConfig.remoteConfig().configValue(forKey: "pricing_model").stringValue!
        let businessModel = PricingModel(rawValue: businessModelRawValue)
        
        let purchaseViewController: PurchaseViewController
        
        switch businessModel {
        case .yearly:
            purchaseViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "YearlySubscriptionPurchaseVC") as! YearlySubscriptionPurchaseVC
        default:
            purchaseViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PurchaseViewController") as! PurchaseViewController
        }
        
        purchaseViewController.onDismiss = { [weak self] in
            if let _ = SpidProducts.store.userPurchasedProVersion() {
                self?.hideProButton()
            }
        }
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            purchaseViewController.modalPresentationStyle = .fullScreen
        }
        else if UIDevice.current.userInterfaceIdiom == .pad {
            purchaseViewController.modalPresentationStyle = .formSheet
        }
        
        self.present(purchaseViewController, animated: true)
    }
    
    @objc func updateExportProgress() {
        guard let progress = exportSession?.progress else { return }
        progressIndicatorView.progressView.progress = progress
    }
        
    func showNoTracksError() {
        let alert = UIAlertController(
          title: "Error",
          message: "Couldn't find video tracks",
          preferredStyle: .alert)
        alert.addAction(UIAlertAction(
          title: "OK",
          style: UIAlertAction.Style.cancel,
          handler: { [weak self] _ in
              self?.navigationController?.popViewController(animated: true)
          }))
        present(alert, animated: true, completion: nil)
    }
    
    func showProButtonIfNeeded() {
        guard SpidProducts.store.userPurchasedProVersion() == nil else {return}
        
        if self.usingProFeatures() {
            self.showProButton()
        }
        else {
            self.hideProButton()
        }
    }
    
    func loopVideo() {
      NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [weak self] notification in
          self?.playerController.player?.seek(to: .zero)
          self?.playerController.player?.play()
      }
    }
}

fileprivate typealias NotificationObservers = EditViewController
extension NotificationObservers {
    @objc func usingSliderChanged() {
        showProButtonIfNeeded()
    }
    
    func usingProFeatures() -> Bool {
        if UserDataManager.main.usingSlider ||
            fps != 30 ||
            !soundOn ||
            fileType == .mp4 {
            
            return true
        }
        return false
    }
    
   @objc func proButtonTapped() {
        showPurchaseViewController()
    }
}
