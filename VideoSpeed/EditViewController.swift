//
//  ViewController.swift
//  VideoSpeed
//
//  Created by oren shalev on 13/07/2023.
//

import UIKit
import AVFoundation
import AVKit

class EditViewController: UIViewController {
    var playerController: AVPlayerViewController!
    var asset: AVAsset!
    var composition: AVMutableComposition!
    var videoComposition: AVMutableVideoComposition!
    var speed: Float = 1
    var fps: Int32 = 30
    var fileType: AVFileType = .mov
    var assetUrl: URL!
    var compositionOriginalDuration: CMTime!
    var compositionVideoTrack: AVMutableCompositionTrack!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    // Bottom tabs
    @IBOutlet weak var speedButton: UIButton!
    @IBOutlet weak var fpsButton: UIButton!
    @IBOutlet weak var fileTypeButton: UIButton!
    var selectedBottomButton: UIButton!

    
    // Navigation right item labels
    var speedLabel: UILabel!
    var fpsLabel: UILabel!
    var fileTypeLabel: UILabel!
    
    // Sections
    var speedSectionVC: SpeedSectionVC!
    var fpsSectionVC: FPSSectionVC!
    var fileTypeSectionVC: FileTypeSectionVC!
    
    @IBOutlet weak var dashboardContainerView: UIView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black, .font: UIFont.boldSystemFont(ofSize: 17)], for: .selected)
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white,
                                                 .font: UIFont.boldSystemFont(ofSize: 17)], for: .normal)
        
        setNavigationItems()
        
        addSpeedSection()
        addFPSSection()
        addFiletypeSection()
        
        showSpeedSection()
        
        asset = AVAsset(url: assetUrl)
        Task {
            let (composition, videoComposition) = await createCompositionWith(speed: speed, fps: fps)
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

        }

       
                
    }

    func createCompositionWith(speed: Float, fps: Int32) async -> (AVMutableComposition, AVMutableVideoComposition) {
        let composition = AVMutableComposition(urlAssetInitializationOptions: nil)

        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: 1)!
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: 2)!
        
        
        let videoTrack = try! await asset.loadTracks(withMediaType: .video)[0]
        let videoDuration = try! await asset.load(.duration)
        
        try? compositionVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoDuration),
                                                                of: videoTrack,
                                                                at: CMTime.invalid)
        
        
        let audioTrack = try! await asset.loadTracks(withMediaType: .audio)[0]
        let audioDuration = try! await asset.load(.duration)
        
        try? compositionAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: audioDuration),
                                                                of: audioTrack,
                                                                at: CMTime.invalid)

        
        compositionOriginalDuration = try! await composition.load(.duration)
        let newDuration = Int64(compositionOriginalDuration.seconds / Double(speed))
        composition.scaleTimeRange(CMTimeRange(start: .zero, duration: compositionOriginalDuration), toDuration: CMTime(value: newDuration, timescale: 1))
        
        

        let naturalSize = try! await videoTrack.load(.naturalSize)
        let preferredTransform = try! await videoTrack.load(.preferredTransform)
        compositionVideoTrack.preferredTransform = preferredTransform

        let videoInfo = orientation(from: preferredTransform)

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
          assetTrack: videoTrack)
        instruction.layerInstructions = [layerInstruction]
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [instruction]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: fps)
        videoComposition.renderSize = videoSize


        return (composition,videoComposition)
        
    }
    
    
    func reloadComposition() async {
        let (composition, videoComposition) = await createCompositionWith(speed: speed, fps: fps)
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
        let exportButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(exportVideo))
        
        speedLabel = createRightItemLabel()
        speedLabel.text = "\(speed)x"

        fpsLabel = createRightItemLabel()
        fpsLabel.text = "\(fps):FPS"

        fileTypeLabel = createRightItemLabel()
        fileTypeLabel.text = fileType == .mov ? "MOV" : "MP4"
        
        let speedItem = UIBarButtonItem(customView: speedLabel)
        let fpsItem = UIBarButtonItem(customView: fpsLabel)
        let fileTypeItem = UIBarButtonItem(customView: fileTypeLabel)

        
        navigationItem.rightBarButtonItems = [exportButton, fileTypeItem, fpsItem, speedItem]
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
        
        let fileExtension = fileType == .mov ? "mov" : "mp4"
        let videoName = UUID().uuidString
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
          .appendingPathComponent(videoName)
          .appendingPathExtension(fileExtension)
        
        exportSession.videoComposition = videoComposition
        exportSession.outputFileType = fileType
        exportSession.outputURL = exportURL
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
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

        }    }
    
    @objc func video(
      _ videoPath: String,
      didFinishSavingWithError error: Error?,
      contextInfo info: AnyObject
    ) {
      let title = (error == nil) ? "Success" : "Error"
      let message = (error == nil) ? "Video was saved" : "Video failed to save"

      let alert = UIAlertController(
        title: title,
        message: message,
        preferredStyle: .alert)
      alert.addAction(UIAlertAction(
        title: "OK",
        style: UIAlertAction.Style.cancel,
        handler: nil))
      present(alert, animated: true, completion: nil)
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

    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) async -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let transform = try! await assetTrack.load(.preferredTransform)

        instruction.setTransform(transform, at: .zero)

        return instruction
    }
    

    private func orientation(from transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
      var assetOrientation = UIImage.Orientation.up
      var isPortrait = false
      if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
        assetOrientation = .right
        isPortrait = true
      } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
        assetOrientation = .left
        isPortrait = true
      } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
        assetOrientation = .up
      } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
        assetOrientation = .down
      }
      
      return (assetOrientation, isPortrait)
    }
    
    // MARK: - Actions

    @IBAction func speedButtonTapped(_ sender: UIButton) {
        setBottomButtonSelected(button: sender)
        showSpeedSection()
    }
    
    @IBAction func fpsButtonTapped(_ sender: UIButton) {
        setBottomButtonSelected(button: sender)
        showFPSSection()
    }
    
    @IBAction func fileTypeButtonTapped(_ sender: UIButton) {
        setBottomButtonSelected(button: sender)
        showFileTypeSection()
    }
    
    @IBAction func segmentedValueChanged(_ segmentedControl: UISegmentedControl) {
        let currentIndex = segmentedControl.selectedSegmentIndex
        switch currentIndex {
        case 0:
            showSpeedSection()
        case 1:
            showFPSSection()
        default:
            showFileTypeSection()
        }
    }
    // MARK: - Sections Logic
    func addSpeedSection() {
        speedSectionVC = SpeedSectionVC()
        speedSectionVC.sliderValueChange = { [weak self] (speed: Float) -> () in
            self?.speedLabel.text = "\(speed)x"
        }
        speedSectionVC.speedDidChange = { [weak self] (speed: Float) -> () in
            guard let self = self else {return}
            self.speed = speed
            Task {
              await self.reloadComposition()
            }
           
        }
        
        addSection(sectionVC: speedSectionVC)
    }
    
    func addFPSSection() {
        fpsSectionVC = FPSSectionVC()
        fpsSectionVC.fpsDidChange = { [weak self] (fps: Int32) in
            self?.fps = fps
            self?.fpsLabel.text = "\(fps):fps"
        }
        addSection(sectionVC: fpsSectionVC)
    }
    
    func addFiletypeSection() {
        fileTypeSectionVC = FileTypeSectionVC()
        fileTypeSectionVC.fileTypeDidChange = { [weak self] (fileType: AVFileType) in
            self?.fileType = fileType
            self?.fileTypeLabel.text = fileType == .mov ? "MOV" : "MP4"
        }
        addSection(sectionVC: fileTypeSectionVC)
    }
    
    func addSection(sectionVC: SectionViewController) {
        addChild(sectionVC)
        dashboardContainerView.addSubview(sectionVC.view)
        speedSectionVC.view.translatesAutoresizingMaskIntoConstraints = false

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
        fileTypeSectionVC.view.isHidden = true
    }

    func showFPSSection() {
        speedSectionVC.view.isHidden = true
        fpsSectionVC.view.isHidden = false
        fileTypeSectionVC.view.isHidden = true
    }
    
    func showFileTypeSection() {
        speedSectionVC.view.isHidden = true
        fpsSectionVC.view.isHidden = true
        fileTypeSectionVC.view.isHidden = false
    }
    
    // MARK: - Custom Logic
    func setBottomButtonSelected(button: UIButton) {
//        selectedBottomButton?.tintColor = UIColor.black
//        selectedBottomButton?.setTitleColor(.white, for: .normal)
//        button.backgroundColor = .white
        button.titleLabel?.textColor = .black
//        button.titleLabel?.backgroundColor = .clear
//        button.titleLabel?.backgroundColor = .green
        button.backgroundColor = .white
        selectedBottomButton = button
    }
}

