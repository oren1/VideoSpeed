//
//  Edit.swift
//  VideoSpeed
//
//  Created by oren shalev on 28/12/2024.
//

import SwiftUI
import AVFoundation

extension EditViewController {
    
    func createEditSections() {
        createSpeedSection()
        createCropSection()
        createFPSSection()
        createSoundSection()
        createFiletypeSection()
        createTrimmerSection()
    }
    
    // MARK: Creating Sections
    func createSpeedSection() {
        speedSectionVC = SpeedSectionVC()
        
        speedSectionVC.sliderValueChange = { [weak self] (speed: Float) -> () in
            self?.speedLabel.text = "\(speed)x"
        }
        
        speedSectionVC.speedDidChange = { [weak self] (speed: Float) -> () in
            self?.speed = speed
            self?.speedLabel.text = "\(speed)x"
            
            Task {
                await UserDataManager.main.currentSpidAsset.updateSpeed(speed: speed)
                await self?.reloadComposition()
                self?.spidPlayerController?.player.play()
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
    
    }
    
    func createCropSection() {
        cropSectionVC = CropSectioVC()
        cropSectionVC.cropSectionChangedStatusTo = { [weak self] (cropStatus: CropStatus) in
            guard let self = self else {return}
            
            switch cropStatus {
            case .cropping:
                addCropViewControllerToTop()
            default:
                Task {
                    /*
                     Before reloading the composition, make sure that the 'rotatedAsset' is ready.
                     The crop will work only for assets that their orientation is the intended orientation
                     of the video
                     */
                    
//                    guard let _ = self.rotatedAsset else
                    if await !UserDataManager.main.currentSpidAsset.assetHasBeenRotated
                    {
                        // 1. Show a loading view until the asset has been rotated
                        self.loadingMediaVC = UIHostingController(rootView: LoadingMediaView(loadingMediaViewModel: self.loadingMediaViewModel))
                        self.loadingMediaVC!.view.backgroundColor = .clear
                        self.loadingMediaVC!.view.frame = self.navigationController!.view.bounds
                        self.navigationController!.view.addSubview(self.loadingMediaVC!.view)
                        return
                    }
                    
                    await self.reloadComposition()
                    self.removeCropVCFromTop()
                }
            }
        }
    }
    
    func createFPSSection() {
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
    }
    
    func createSoundSection()  {
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
        
    }
    
    func createFiletypeSection() {
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
       

    }
    
    func createTrimmerSection() {
        trimmerSectionVC = TrimmerSectionVC()
        trimmerSectionVC.delegate = self
        trimmerSectionVC.timeRangeDidChange = { [weak self] timeRange in
            Task {
                await UserDataManager.main.currentSpidAsset.updateTimeRange(timeRange: timeRange)
                await self?.reloadComposition()
            }
        }
        let _ = trimmerSectionVC.view
    }
    
    
    // MARK: Adding Sections
    func addSpeedSection() {
        addSection(sectionVC: speedSectionVC)
        currentShownSection = speedSectionVC
    }
    
    func addCropSection() {
        addSection(sectionVC: cropSectionVC)
        currentShownSection = cropSectionVC
    }
    
    func addFPSSection() {
        addSection(sectionVC: fpsSectionVC)
        currentShownSection = fpsSectionVC
    }
    
    func addSoundSection()  {
        addSection(sectionVC: soundSectionVC)
        currentShownSection = soundSectionVC
    }
    
    func addFiletypeSection() {
        addSection(sectionVC: moreSectionVC)
        currentShownSection = moreSectionVC

    }
    
    func addTrimmerSection() {
        addSection(sectionVC: trimmerSectionVC)
        currentShownSection = trimmerSectionVC
    }
    
}
