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
    var speed: Float = 2
    var fps: Int32 = 30
    var fileType: String = "mov"
    var assetUrl: URL!
    
    
    @IBOutlet weak var speedButton: UIButton!
    @IBOutlet weak var fpsButton: UIButton!
    @IBOutlet weak var fileTypeButton: UIButton!
    
    var speedLabel: UILabel!
    var fpsLabel: UILabel!
    var fileTypeLabel: UILabel!
    
    var speedSectionVC: SpeedSectionVC!
    var fpsSectionVC: FPSSectionVC!
    var fileTypeSectionVC: FileTypeSectionVC!
    
    @IBOutlet weak var dashboardContainerView: UIView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationItems()
        
        addSpeedSection()
        addFPSSection()
        addFiletypeSection()
        
        asset = AVAsset(url: assetUrl)

        composition = AVMutableComposition(urlAssetInitializationOptions: nil)

        Task {
            let compositioVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: 1)!
            let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: 2)!
            
            
            let videoTrack = try! await asset.loadTracks(withMediaType: .video)[0]
            let videoDuration = try! await asset.load(.duration)
            
            try? compositioVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoDuration),
                                                                    of: videoTrack,
                                                                    at: CMTime.invalid)
            
            
            let audioTrack = try! await asset.loadTracks(withMediaType: .audio)[0]
            let audioDuration = try! await asset.load(.duration)
            
            try? compositionAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: audioDuration),
                                                                    of: audioTrack,
                                                                    at: CMTime.invalid)

            
            let compositionDuration = try! await composition.load(.duration)
            let newDuration = Int64(compositionDuration.seconds / 2)
            composition.scaleTimeRange(CMTimeRange(start: .zero, duration: compositionDuration), toDuration: CMTime(value: newDuration, timescale: 1))
            
            

            let naturalSize = try! await videoTrack.load(.naturalSize)
//            let videoSize = CGSize(width: naturalSize.width, height: naturalSize.height)
            let preferredTransform = try! await videoTrack.load(.preferredTransform)
            compositioVideoTrack.preferredTransform = preferredTransform

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
              for: compositioVideoTrack,
              assetTrack: videoTrack)
            instruction.layerInstructions = [layerInstruction]
            
            videoComposition = AVMutableVideoComposition()
            videoComposition.instructions = [instruction]
            videoComposition.frameDuration = CMTimeMake(value: 1, timescale: fps)
            videoComposition.renderSize = videoSize

            
            let playerItem = AVPlayerItem(asset: composition)
            playerItem.audioTimePitchAlgorithm = .spectral
            playerItem.videoComposition = videoComposition
            
            let player = AVPlayer(playerItem: playerItem)
            
            playerController = AVPlayerViewController()
            playerController.player = player
            addPlayerToTop()
            
        }
        
       
                
    }

    func setNavigationItems() {
        let exportButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(exportVideo))
        
        speedLabel = createRightItemLabel()
        speedLabel.text = "\(speed)x"

        fpsLabel = createRightItemLabel()
        fpsLabel.text = "\(fps):FPS"

        fileTypeLabel = createRightItemLabel()
        fileTypeLabel.text = fileType
        
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
        label.layer.masksToBounds = false
        
        return label
    }
    
    @objc func exportVideo() {
        print("expportVideo")
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

    @IBAction func speedButtonTapped(_ sender: Any) {
        showSpeedSection()
    }
    
    @IBAction func fpsButtonTapped(_ sender: Any) {
        showFPSSection()
    }
    
    @IBAction func fileTypeButtonTapped(_ sender: Any) {
        showFileTypeSection()
    }
    
    // MARK: - Sections Logic
    func addSpeedSection() {
        speedSectionVC = SpeedSectionVC()
        speedSectionVC.speedDidChange = { [weak self] (speed: Float) -> () in
            self?.speedLabel.text = "\(speed)x"
        }
        
        addSection(sectionVC: speedSectionVC)
    }
    
    func addFPSSection() {
        fpsSectionVC = FPSSectionVC()
        fpsSectionVC.fpsDidChange = { [weak self] (fps: Int32) in
            self?.fps = fps
            self?.fpsLabel.text = "\(fps)-fps"
        }
        addSection(sectionVC: fpsSectionVC)
    }
    
    func addFiletypeSection() {
        fileTypeSectionVC = FileTypeSectionVC()
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
}

