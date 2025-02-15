//
//  ViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 13/07/2023.
//

import UIKit
import AVFoundation
import CoreImage
import AVKit
import FirebaseRemoteConfig
import SwiftUI
import Combine

enum ExportButtonType: String {
    case noText = "noText"
    case withText = "withText"
}

enum ForceShowPurchaseScreen: Int {
    case dontForce = 0, forceShow
}

class EditViewController: UIViewController, TrimmerSectionViewDelegate {
    var playerController: AVPlayerViewController!
    var asset: AVAsset!
    
    var composition: AVMutableComposition!
    var videoComposition: AVMutableVideoComposition!
    var speed: Float = 1
    var fps: Int32 = 30
    var fileType: AVFileType = .mov
    var soundOn: Bool! = true
    var assetUrl: URL!
    var videoSize: CGSize!
    var compositionOriginalDuration: CMTime!
    var compositionVideoTrack: AVMutableCompositionTrack!
    var exportSession: AVAssetExportSession?
    var timer: Timer?
    var proButton: UIButton!
    var cropViewController: CropViewController!
    var rotatedAsset: AVAsset?
    var loadingMediaVC: UIHostingController<LoadingMediaView>?
    var loadingMediaViewModel = LoadingMediaViewModel()
    var assetRotator: AssetRotator?
    var assetRotateProgressSubscription: AnyCancellable?
    var isUsingCropFeatureSubscriber: AnyCancellable?
    var isCropFeatureFree: Bool!
    var currentShownSection: SectionViewController!
    var spidPlayerController: SpidPlayerViewController!
    var selectedMenuItem: MenuItem!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    private(set) var sectionInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
    @IBOutlet weak var bottomMenuCollectionView: UICollectionView!
    let menuItemReuseIdentifier = "MenuItem"
    let menuItems: [MenuItem] = [MenuItem(id: .speed , title: "SPEED", imageName: "timer"),
                                 MenuItem(id: .trim , title: "TRIM", imageName: "timeline.selection"),
                                 MenuItem(id: .crop , title: "CROP", imageName: "crop"),
                                 MenuItem(id: .fps , title: "FPS", imageName: "square.stack.3d.down.right.fill"),
                                 MenuItem(id: .sound , title: "SOUND", imageName: "speaker.wave.2"),
                                 MenuItem(id: .text , title: "TEXT", imageName: "textformat.alt"),
                                 MenuItem(id: .more , title: "MORE", imageName: "ellipsis")
    ]
    
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
    var cropSectionVC: CropSectioVC!
    var trimmerSectionVC: TrimmerSectionVC!
    var textSectionVC: TextSectionVC!
    
    var editSections: [SectionViewController] = []
    
    @IBOutlet weak var dashboardContainerView: UIView!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        segmentedControl.setTitle("SPEED", forSegmentAt: 0)
//        segmentedControl.setTitle("TRIM", forSegmentAt: 1)
//        segmentedControl.setTitle("CROP", forSegmentAt: 2)
//        segmentedControl.setTitle("FPS", forSegmentAt: 3)
//        segmentedControl.setTitle("SOUND", forSegmentAt: 4)
//        segmentedControl.insertSegment(withTitle: "MORE", at: 5, animated: false)
//        
//        
//        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black, .font: UIFont.boldSystemFont(ofSize: 14)], for: .selected)
//        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white,
//                                                 .font: UIFont.boldSystemFont(ofSize: 14)], for: .normal)
        selectedMenuItem = menuItems.first
        
        bottomMenuCollectionView.delegate = self
        bottomMenuCollectionView.dataSource = self
        
        setNavigationItems()
        proButton = createProButton()
        
        createEditSections()
        addSpeedSection()
        
        
        isCropFeatureFree = RemoteConfig.remoteConfig().configValue(forKey: "crop_feature_free").numberValue.boolValue
        
        NotificationCenter.default.addObserver(self, selector: #selector(usingSliderChanged), name: Notification.Name("usingSliderChanged"), object: nil)
        isUsingCropFeatureSubscriber = UserDataManager.main.$isUsingCropFeature.sink(receiveValue: { [weak self] isUsingCropFeature in
            self?.showProButtonIfNeeded()
        })
        
        Task {
            await createCropViewController()
            let asset = await UserDataManager.main.currentSpidAsset.getAsset()
            guard let (composition, videoComposition) = await createCompositionWith(asset: asset, speed: speed, fps: fps, soundOn: soundOn) else {
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
            
            // playerController = AVPlayerViewController()
            // playerController.player = player
            // addPlayerToTop()

            spidPlayerController = SpidPlayerViewController()
            spidPlayerController.player = player
            addSpidPlayerTop()
            loopVideo()
            
            Task {
                await rotateVideoForCropFeature()
            }
        }
        
        //        segmentedControl.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.white], for: .normal)
        //
        //        segmentedControl.setTitleTextAttributes([.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.black], for: .selected)
        
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false;

//        let forceShow = RemoteConfig.remoteConfig().configValue(forKey: "forceShow").numberValue.boolValue
//        
//        if forceShow && SpidProducts.store.userPurchasedProVersion() == nil {
//            if let lastApearanceOfPurchaseScreen = UserDataManager.main.lastApearanceOfPurchaseScreen {
//                let now = Date().timeIntervalSince1970
//                if lastApearanceOfPurchaseScreen + (60 * 60 * 24) < now {
//                    forceShowPurchaseScreen()
//                }
//                return
//            }
//            else {
//                let now = Date().timeIntervalSince1970
//                UserDataManager.main.lastApearanceOfPurchaseScreen = now
//            }
//        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true;
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
    
    func createCompositionWith(asset: AVAsset, speed: Float, fps: Int32, soundOn: Bool) async -> (composition: AVMutableComposition, videoComposition: AVMutableVideoComposition)? {
        let composition = AVMutableComposition(urlAssetInitializationOptions: nil)

        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: 1)!
        let timeRange = await UserDataManager.main.currentSpidAsset.timeRange
        
        if let audioTracks = try? await asset.loadTracks(withMediaType: .audio),
           soundOn && audioTracks.count > 0 {
            let audioTrack = audioTracks[0]
            let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: 2)!
            let audioDuration = try! await asset.load(.duration)
            
            try? compositionAudioTrack.insertTimeRange(timeRange,
                                                       of: audioTrack,
                                                       at: CMTime.invalid)
        }
        
        
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first,
              let videoDuration = try? await asset.load(.duration),
              let naturalSize = try? await videoTrack.load(.naturalSize),
              let preferredTransform = try? await videoTrack.load(.preferredTransform) else {return nil}
        
        
        try? compositionVideoTrack.insertTimeRange(timeRange,
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
        
        print("naturalSize", naturalSize)
        print("videoSize \(videoSize)")
        
        let croppedVideoRect = aspectRatioCroppedVideoRect(videoSize)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(
            start: .zero,
            duration: composition.duration)
        
        // If the user is not using crop feature then use the regular 'compositionLayerInstruction'
        
        let layerInstruction = await compositionLayerInstruction(
            for: compositionVideoTrack,
            assetTrack: videoTrack,
            videoSize: videoSize,
            isPortrait: videoInfo.isPortrait,
            cropRect: croppedVideoRect)
        
        instruction.layerInstructions = [layerInstruction]
        
       
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [instruction]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: fps)
        videoComposition.renderSize = croppedVideoRect.size
//        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
//          postProcessingAsVideoLayer: videoLayer,
//          in: outputLayer)
        //                videoComposition.renderSize = CGSize(width: videoSize.width, height: videoSize.height)
        //                videoComposition.renderSize = CGSize(width: naturalSize.width, height: naturalSize.height)
        //        videoComposition.customVideoCompositorClass = CustomVideoCompositor.self
        
        return (composition,videoComposition)
        
    }
    
    private func add(labelView: LabelView, to layer: CALayer, videoSize: CGSize) {
        
        let scaleX = videoSize.width / spidPlayerController.videoContainerView.frame.width
        let scaleY = videoSize.height / spidPlayerController.videoContainerView.frame.height
        
        let labelViewCopy = labelView.copyLabelView()
//        let scaledLabel = labelViewCopy.scaledBy(scaleX)
//        scaledLabel.layer.displayIfNeeded()
//        labelViewCopy.layer.displayIfNeeded()
        layer.addSublayer(labelView.layer)
//        layer.addSublayer(labelViewCopy.layer)

    }
    
    func aspectRatioCroppedVideoRect(_ videoSize: CGSize) -> CGRect {
        guard let videoRect = cropViewController.videoRect else
        {
            /* cropViewController.videoRect will exist only if the user cropped the video size with the CropPickerView at least once.
             if he did't then return the full size of video
             */
            return CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        }
        let aspectRatioX = videoSize.width / cropViewController.cropPickerView.frame.width
        let aspectRatioY = videoSize.height / cropViewController.cropPickerView.frame.height
        
        let x = videoRect.origin.x * aspectRatioX
        let y = videoRect.origin.y * aspectRatioY
        let width = videoRect.width * aspectRatioX
        let height = videoRect.height * aspectRatioY
        let frame = CGRect(x: x, y: y, width: width, height: height)
        return frame
    }
    
    @MainActor
    func reloadComposition() async {
        let asset = await UserDataManager.main.currentSpidAsset.getAsset()
        guard let (composition, videoComposition) = await createCompositionWith(asset: asset, speed: speed, fps: fps, soundOn: soundOn) else {
            return showNoTracksError()
        }
        self.composition = composition
        self.videoComposition = videoComposition
        let compositionCopy = self.composition.copy() as! AVComposition
        let videoCompositionCopy = self.videoComposition.copy() as! AVVideoComposition
        
        let playerItem = AVPlayerItem(asset: compositionCopy)
        playerItem.audioTimePitchAlgorithm = .spectral
        playerItem.videoComposition = videoCompositionCopy
        spidPlayerController.player?.replaceCurrentItem(with: playerItem)
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
        AnalyticsManager.exportButtonTapped()
        
        guard  SpidProducts.store.userPurchasedProVersion() != nil ||
                UserDataManager.main.userBenefitStatus == .entitled else {
            
            if !usingProFeatures() {
                Task {
                    await self.exportVideo()
                }
                return
            }
            else {
                // show alert for purchase
                showProFeatureAlert()
                return
            }
        }
        
        Task {
           await exportVideo()

        }
    }
    
    @objc func exportVideo() async {
        let theComposition = composition.copy() as! AVComposition
//        let videoComposition = videoComposition.copy() as! AVVideoComposition
        
        let videoSize = await UserDataManager.main.currentSpidAsset.videoSize
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        videoLayer.isGeometryFlipped = true
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
        overlayLayer.isGeometryFlipped = true
        let outputLayer = CALayer()
        outputLayer.frame = CGRect(origin: .zero, size: videoSize)
        outputLayer.addSublayer(videoLayer)
        outputLayer.addSublayer(overlayLayer)
        
        for labelView in UserDataManager.main.overlayLabelViews {
            add(labelView: labelView, to: overlayLayer, videoSize: videoSize)
        }
        
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
          postProcessingAsVideoLayer: videoLayer,
          in: outputLayer)
        
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
                    
                    print("save to path: \(exportURL.relativePath)")
                    // 3
                    UISaveVideoAtPathToSavedPhotosAlbum(exportURL.relativePath, self, #selector(self.video(_:didFinishSavingWithError:contextInfo:)),nil)
                    Task {
                        await self.sendExportCompletionEvents()
                    }
                    
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
    
    func addSpidPlayerTop() {
        //add as a childviewcontroller
//        let spidPlayerViewController = SpidPlayerViewController()
        addChild(spidPlayerController)
        
        // Add the child's View as a subview
        self.view.addSubview(spidPlayerController.view)
        
        spidPlayerController.view.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            spidPlayerController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            spidPlayerController.view.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor),
            spidPlayerController.view.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor),
            spidPlayerController.view.bottomAnchor.constraint(equalTo: self.dashboardContainerView.topAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
        
        // tell the childviewcontroller it's contained in it's parent
        spidPlayerController.didMove(toParent: self)
    }
    
    @MainActor
    func addCropViewControllerToTop() {
        //add as a childviewcontroller
        addChild(cropViewController)
        
        // Add the child's View as a subview
         
        self.view.addSubview(cropViewController.view)
        if view.subviews.contains(where: {$0 == proButton}) {
            self.view.bringSubviewToFront(proButton)
        }

        // give the cropPickerView it's parameters
        
        cropViewController.view.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            cropViewController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            cropViewController.view.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor),
            cropViewController.view.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor),
            cropViewController.view.bottomAnchor.constraint(equalTo: self.dashboardContainerView.topAnchor),
        ]
        NSLayoutConstraint.activate(constraints)
        
        // tell the childviewcontroller it's contained in it's parent
        cropViewController.didMove(toParent: self)
        cropViewController.view.layoutIfNeeded()
        cropViewController.updateCropViewPickerSize()
        cropViewController.view.layoutIfNeeded()
        
    }
    
    func removeCropVCFromTop() {
        cropViewController.willMove(toParent: nil)
        cropViewController.view.removeFromSuperview()
        cropViewController.removeFromParent()
    }
    
    
    func removeLoadingMediaVC() {
        loadingMediaVC?.willMove(toParent: nil)
        loadingMediaVC?.view.removeFromSuperview()
        loadingMediaVC?.removeFromParent()
        loadingMediaVC = nil
    }
    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack, videoSize: CGSize, isPortrait: Bool, cropRect: CGRect) async -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        
        let transform = try! await assetTrack.load(.preferredTransform)
        
        if isPortrait {
            var newTransform = CGAffineTransform(translationX: 0, y: 0)
            newTransform = newTransform.rotated(by: CGFloat(90 * Double.pi / 180))
            newTransform = newTransform.translatedBy(x: 0, y: -videoSize.width)
            instruction.setTransform(newTransform, at: .zero)
            
        }
        else {
            instruction.setCropRectangle(CGRect(x: cropRect.origin.x, y: cropRect.origin.y, width: cropRect.size.width, height: cropRect.size.height), at: .zero)
            
            let newTransform = transform.translatedBy(x: -cropRect.origin.x, y: -cropRect.origin.y)
            instruction.setTransform(newTransform, at: .zero)
            
        }
        
        return instruction
    }
    
    
    // MARK: - Actions
    @MainActor
    @IBAction func segmentedValueChanged(_ segmentedControl: UISegmentedControl) {
        let currentIndex = segmentedControl.selectedSegmentIndex
        if currentIndex != 2 {
            removeCropVCFromTop()
        }
        
        currentShownSection.remove()

        switch currentIndex {
        case 0:
            addSpeedSection()
        case 1:
            addTrimmerSection()
        case 2:
            addCropSection()
            addCropViewControllerToTop()
        case 3:
            addFPSSection()
        case 4:
            addSoundSection()
        case 5:
            addFiletypeSection()
        default:
            print("no such case")
        }
    }
    
    
    
    // MARK: - Sections Logic
    func showProButton() {
        
        self.view.addSubview(proButton)
        self.view.bringSubviewToFront(proButton)

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
    
    
    func createCropViewController() async {
        cropViewController = CropViewController()
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first,
              let naturalSize = try? await videoTrack.load(.naturalSize),
              let preferredTransform = try? await videoTrack.load(.preferredTransform) else {return}
        
        
        let videoInfo = VideoHelper.orientation(from: preferredTransform)
        let videoSize: CGSize
        
        if videoInfo.isPortrait {
            videoSize = CGSize(
                width: naturalSize.height,
                height: naturalSize.width)
        } else {
            videoSize = naturalSize
        }
        
        cropViewController.videoAspectRatio = videoSize.width / videoSize.height
        
        //         Sometimes the portrait video is saved in landscape, so this is a fix that rotates the generated image back to it's
        //         portrait original intended presentation
        
        if videoInfo.isPortrait {
            var templateImage = await generateTemplateImage(asset: asset)
            templateImage = UIImage(cgImage: templateImage.cgImage!, scale: templateImage.scale, orientation: .right)
            cropViewController.templateImage = templateImage
        }
        else {
            cropViewController.templateImage = await generateTemplateImage(asset: asset)
        }
        
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
                                               fileType: fileType,
                                               usingCropFeature: UserDataManager.main.isUsingCropFeature)
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
            usingProFeaturesAlertView.heightAnchor.constraint(equalToConstant: 350),
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
        
        let purchaseViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "YearlySubscriptionPurchaseVC") as! YearlySubscriptionPurchaseVC
        purchaseViewController.productIdentifier = SpidProducts.yearlySubscription
        purchaseViewController.onDismiss = { [weak self] in
            if let _ = SpidProducts.store.userPurchasedProVersion() {
                self?.hideProButton()
            }
        }
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            purchaseViewController.modalPresentationStyle = .automatic
        }
        else if UIDevice.current.userInterfaceIdiom == .pad {
            purchaseViewController.modalPresentationStyle = .formSheet
        }
        
        self.present(purchaseViewController, animated: true)
    }
    
    func forceShowPurchaseScreen() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
            guard let self = self else {return}
            showPurchaseViewController()
            
            let now = Date().timeIntervalSince1970
            UserDataManager.main.lastApearanceOfPurchaseScreen = now
        }
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
        guard SpidProducts.store.userPurchasedProVersion() == nil &&
                UserDataManager.main.userBenefitStatus != .entitled else {return}
        
        if self.usingProFeatures() {
            self.showProButton()
        }
        else {
            self.hideProButton()
        }
    }
    
    func loopVideo() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [weak self] notification in
            
            self?.spidPlayerController.player?.seek(to: .zero)
            self?.spidPlayerController.player?.play()
        }
    }
    
    func sendExportCompletionEvents() async {
        if UserDataManager.main.usingSlider { AnalyticsManager.speedUsedOnExportEvent() }
        if fps != 30 { AnalyticsManager.fpsUsedOnExportEvent() }
        if !soundOn { AnalyticsManager.soundUsedOnExportEvent() }
        if fileType == .mp4 { AnalyticsManager.fileTypeUsedOnExportEvent() }
        if UserDataManager.main.isUsingCropFeature { AnalyticsManager.cropUsedOnExportEvent() }
        if await UserDataManager.main.isUsingTrimFeature() { AnalyticsManager.trimUsedOnExportEvent()}
    }
    
    func generateTemplateImage(asset: AVAsset) async -> UIImage {
        let generator = AVAssetImageGenerator(asset: asset)
        let time = CMTime(seconds: 0.0, preferredTimescale: 600)
        let times = [NSValue(time: time)]
        
        return await withCheckedContinuation { continuation in
            
            generator.generateCGImagesAsynchronously(forTimes: times) { [weak self] _, image, _, result, error in
                guard let _ = self, let image = image else {return}
                continuation.resume(returning: UIImage(cgImage: image))
                
            }
            
        }
        
    }
    
    func rotateVideoForCropFeature() async {
        // Creat AssetRotator instance and listen to progress changes and done rotating chenges
        assetRotator = AssetRotator(asset: asset)
        assetRotateProgressSubscription = assetRotator?.$progress.sink { [weak self] progress in
            self?.loadingMediaViewModel.progress = progress
        }
        let rotatedAsset = await assetRotator!.rotateVideoToIntendedOrientation()
        await UserDataManager.main.currentSpidAsset.updateRotatedAsset(rotatedAsset: rotatedAsset)
        // I don't want the video to reload after the rotated asset is ready, because it can case a bug
        // that the video reloads in the middle of playing.
        // if the 'LoadingMediaView' is shown when the rotation finished it means that the user pressed 'done' cropping.
        // so if the LoadingMediaView shown, remove it and reload the composition
        
        if let _ = loadingMediaVC {
            removeLoadingMediaVC()
            await self.reloadComposition()
            self.removeCropVCFromTop()
        }
        
        assetRotator = nil
        
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
