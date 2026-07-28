//
//  Edit.swift
//  VideoSpeed
//
//  Created by oren shalev on 28/12/2024.
//

import SwiftUI
import AVFoundation
import Combine

extension EditViewController {
    
    func createEditSections() {
        createSpeedSection()
        createImageDurationSection()
        createCropSection()
        createFPSSection()
        createSoundSection()
        createAudioSection()
        createFiletypeSection()
        createTrimmerSection()
        createSplitSection()
        createFilterSection()
        createTextSection()
        createCaptionsSection()
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
            guard let self = self else { return }
            Task {
                await UserDataManager.main.currentSpidAsset.updateSpeed(speed: speed)
                /* Updating whether at least one 'SpidAsset' is using the slider.
                 i.e it's speed value is different from 0.25, 0.5, 1, 1.5 or 2 */
                UserDataManager.main.usingSlider = await UserDataManager.main.isUsingSliderPrecision()
                await self.reloadComposition()
                let startTime = self.getStartTimeForCurrentSpidAsset()
                await self.spidPlayerController?.player?.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
                self.spidPlayerController?.player.play()
                await self.textSectionVC.createTrimmerView()
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

    func createImageDurationSection() {
        imageDurationSectionVC = ImageDurationSectionVC()

        imageDurationSectionVC.durationDidChange = { [weak self] duration in
            self?.speedLabel.text = self?.formatDurationLabel(duration)
        }

        imageDurationSectionVC.durationDidCommit = { [weak self] duration in
            guard let self else { return }
            self.speedLabel.text = self.formatDurationLabel(duration)
            Task {
                let timescale: CMTimeScale = 600
                let newRange = CMTimeRange(
                    start: .zero,
                    duration: CMTime(seconds: duration, preferredTimescale: timescale)
                )
                await UserDataManager.main.currentSpidAsset.updateTimeRange(timeRange: newRange)
                await UserDataManager.main.currentSpidAsset.clearTrimmerHandleConstants()
                await self.reloadComposition()
                let startTime = self.getStartTimeForCurrentSpidAsset()
                await self.spidPlayerController?.player?.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero)
                self.spidPlayerController?.player.play()
                await self.textSectionVC.createTrimmerView()
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
                    let currentSpidAsset = UserDataManager.main.currentSpidAsset!
                    if await !currentSpidAsset.assetHasBeenRotated
                    {
                        // 1. Show a loading view until the asset has been rotated
                        self.loadingMediaVC = UIHostingController(rootView: LoadingMediaView(loadingMediaViewModel: self.loadingMediaViewModel))
                        self.loadingMediaVC!.view.backgroundColor = .clear
                        self.loadingMediaVC!.view.frame = self.navigationController!.view.bounds
                        self.navigationController!.view.addSubview(self.loadingMediaVC!.view)
                        
                        let asset = await currentSpidAsset.getOriginalAsset()
                        // Start rotating the asset
                        let assetRotator = AssetRotator(asset: asset)
                        self.assetRotateProgressSubscription = assetRotator.$progress
                            .receive(on: DispatchQueue.main)
                            .sink { progress in
                                /* Update the loadingMediaViewModel's progress variable so that the 'loadingMediaVC'
                                 will be rendered with the new progress. */
                                print("progress: \(progress)")
                                self.loadingMediaViewModel.progress = progress
                            }
                        let rotatedAsset = await assetRotator.rotateVideoToIntendedOrientation()
                        await currentSpidAsset.updateRotatedAsset(rotatedAsset: rotatedAsset)
                        self.loadingMediaVC?.remove()
                    }
                    
                    await self.reloadComposition()
                    self.removeCropVCFromTop()
                }
            }
        }
        
        cropSectionVC.closeTapped = { [weak self] in
            self?.removeCropVCFromTop()
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
            guard let self = self else { return }
            self.soundOn = soundOn
            let imageName = soundOn ? "volume.2.fill" : "volume.slash"
            self.soundButton.setImage(UIImage(systemName: imageName), for: .normal)
            Task {
               await UserDataManager.main.currentSpidAsset.updateSound(soundOn: soundOn)
               UserDataManager.main.soundOff = await UserDataManager.main.soundOff()
               await self.reloadComposition()
               let startTime = self.getStartTimeForCurrentSpidAsset()
               await self.spidPlayerController?.player?.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
                
                Task{@MainActor in
                    self.showProButtonIfNeeded()
                }
            }
        }
        soundSectionVC.userNeedsToPurchase = {[weak self] in
            self?.showPurchaseViewController()
        }
        
    }

    func createAudioSection() {
        audioSectionVC = AudioSectionVC()
        audioSectionVC.requestAddAudio = { [weak self] in
            self?.presentAudioImportOptions()
        }
        audioSectionVC.requestEditSource = { [weak self] in
            self?.presentSourceAudioTrimmer()
        }
        audioSectionVC.timelineRangeDidChange = { [weak self] range in
            guard let self else { return }
            guard var track = UserDataManager.main.backgroundAudioTrack else { return }
            // #region agent log
            DebugSessionLog.write(
                hypothesisId: "H4",
                location: "EditSections.createAudioSection:timelineRangeDidChange:beforeUpdate",
                message: "received timeline range change from UI",
                data: [
                    "incomingStart": range.start.seconds,
                    "incomingDuration": range.duration.seconds,
                    "oldTimelineStart": track.timelineTimeRange.start.seconds,
                    "oldTimelineDuration": track.timelineTimeRange.duration.seconds
                ]
            )
            // #endregion
            track.updateTimelineTimeRange(range)
            UserDataManager.main.backgroundAudioTrack = track
            // #region agent log
            DebugSessionLog.write(
                hypothesisId: "H4",
                location: "EditSections.createAudioSection:timelineRangeDidChange:afterUpdate",
                message: "updated track and starting reloadComposition",
                data: [
                    "newTimelineStart": track.timelineTimeRange.start.seconds,
                    "newTimelineDuration": track.timelineTimeRange.duration.seconds,
                    "newSourceDuration": track.sourceTimeRange.duration.seconds
                ]
            )
            // #endregion
            Task {
                await self.reloadComposition(refreshSectionThumbnails: false)
                await MainActor.run {
                    self.audioSectionVC.configure(
                        track: UserDataManager.main.backgroundAudioTrack,
                        compositionDuration: self.composition?.duration ?? .zero,
                        timelineAsset: self.spidPlayerController?.player?.currentItem?.asset
                    )
                }
            }
        }
    }

    func presentSourceAudioTrimmer() {
        guard let track = UserDataManager.main.backgroundAudioTrack else { return }

        spidPlayerController?.player?.pause()

        let sourceVC = AudioSourceTrimmerVC()
        sourceVC.configure(track: track)
        sourceVC.onSourceRangeChanged = { [weak self] range in
            guard let self else { return }
            guard var current = UserDataManager.main.backgroundAudioTrack else { return }
            current.updateSourceTimeRange(range)
            UserDataManager.main.backgroundAudioTrack = current
            Task {
                await self.reloadComposition(refreshSectionThumbnails: false)
                await MainActor.run {
                    self.audioSectionVC.configure(
                        track: UserDataManager.main.backgroundAudioTrack,
                        compositionDuration: self.composition?.duration ?? .zero,
                        timelineAsset: self.spidPlayerController?.player?.currentItem?.asset
                    )
                }
            }
        }
        sourceVC.onVolumeChanged = { [weak self] volume in
            guard let self else { return }
            guard var current = UserDataManager.main.backgroundAudioTrack else { return }
            current.updateVolume(volume)
            UserDataManager.main.backgroundAudioTrack = current
            Task {
                await self.reloadComposition(refreshSectionThumbnails: false)
            }
        }
        sourceVC.onDone = { [weak self] in
            self?.spidPlayerController?.player?.play()
            self?.dismiss(animated: true)
        }

        sourceVC.modalPresentationStyle = .pageSheet
        if let sheet = sourceVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
        }
        present(sourceVC, animated: true)
        sourceVC.presentationController?.delegate = self
    }

    private func presentAudioImportOptions() {
        let sheetView = AudioImportOptionsSheetView(
            onSelect: { [weak self] option in
                self?.dismiss(animated: true) {
                    switch option {
                    case .extractFromVideo:
                        self?.presentExtractAudioFromVideo()
                    case .importFromMusic:
                        self?.presentImportAudioFromMusic()
                    case .record:
                        self?.presentRecordAudio()
                    }
                }
            },
            onCancel: { [weak self] in
                self?.dismiss(animated: true)
            }
        )

        let sheetVC = UIHostingController(rootView: sheetView)
        sheetVC.modalPresentationStyle = .pageSheet

        if let sheetPresentationController = sheetVC.sheetPresentationController {
            sheetPresentationController.detents = [.custom(resolver: { _ in 332 })]
            sheetPresentationController.prefersGrabberVisible = true
            sheetPresentationController.preferredCornerRadius = 16
        }

        present(sheetVC, animated: true)
    }

    private func presentExtractAudioFromVideo() {
        let presenter = VideoLibraryPickerPresenter()
        videoLibraryPickerPresenter = presenter

        presenter.present(from: self) { [weak self] videoURL, displayName in
            guard let self else { return }
            self.videoLibraryPickerPresenter = nil
            self.extractAndApplyBackgroundAudio(from: videoURL, displayName: "extracted-audio")
        } onCancel: { [weak self] in
            self?.videoLibraryPickerPresenter = nil
        }
    }

    private func extractAndApplyBackgroundAudio(from videoURL: URL, displayName: String) {
        showLoading()
        Task {
            do {
                let audioURL = try await AudioExtractor.extractAudio(from: videoURL)
                await MainActor.run { self.hideLoading() }
                self.applyBackgroundAudio(
                    from: audioURL,
                    displayName: displayName,
                    sourceId: UUID().uuidString,
                    source: .extractedFromVideo
                )
            } catch {
                await MainActor.run {
                    self.hideLoading()
                    let alert = UIAlertController(
                        title: "Could Not Extract Audio",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private func presentImportAudioFromMusic() {
        let presenter = MusicLibraryPickerPresenter()
        musicLibraryPickerPresenter = presenter

        presenter.present(from: self) { [weak self] libraryAssetURL, displayName in
            guard let self else { return }
            self.musicLibraryPickerPresenter = nil
            self.importAndApplyBackgroundAudio(from: libraryAssetURL, displayName: displayName)
        } onCancel: { [weak self] in
            self?.musicLibraryPickerPresenter = nil
        } onError: { [weak self] error in
            // #region agent log
            DebugSessionLog.write(
                hypothesisId: "E",
                location: "EditViewController.presentImportAudioFromMusic.onError",
                message: "import error alert",
                data: ["error": error.localizedDescription]
            )
            // #endregion
            self?.musicLibraryPickerPresenter = nil
            let alert = UIAlertController(
                title: "Could Not Import Song",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }

    private func importAndApplyBackgroundAudio(from libraryAssetURL: URL, displayName: String) {
        showLoading()
        // #region agent log
        DebugSessionLog.write(
            hypothesisId: "C",
            location: "EditViewController.importAndApplyBackgroundAudio",
            message: "export started with loading",
            data: ["scheme": libraryAssetURL.scheme ?? "nil", "title": displayName],
            runId: "post-fix"
        )
        // #endregion
        Task {
            do {
                let audioURL = try await MusicLibraryAudioExporter.export(from: libraryAssetURL)
                // #region agent log
                DebugSessionLog.write(
                    hypothesisId: "C",
                    location: "EditViewController.importAndApplyBackgroundAudio",
                    message: "export succeeded",
                    data: [
                        "destExists": FileManager.default.fileExists(atPath: audioURL.path),
                        "scheme": libraryAssetURL.scheme ?? "nil"
                    ],
                    runId: "post-fix"
                )
                // #endregion
                await MainActor.run { self.hideLoading() }
                self.applyBackgroundAudio(
                    from: audioURL,
                    displayName: displayName,
                    sourceId: UUID().uuidString,
                    source: .musicLibrary
                )
            } catch {
                // #region agent log
                DebugSessionLog.write(
                    hypothesisId: "C",
                    location: "EditViewController.importAndApplyBackgroundAudio",
                    message: "export failed",
                    data: ["error": error.localizedDescription],
                    runId: "post-fix"
                )
                // #endregion
                await MainActor.run {
                    self.hideLoading()
                    let alert = UIAlertController(
                        title: "Could Not Import Song",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    private func presentRecordAudio() {
        presentAudioImportSheet(
            rootView: RecordAudioView(
                onCancel: { [weak self] in
                    self?.dismiss(animated: true)
                },
                onComplete: { [weak self] fileURL in
                    self?.dismiss(animated: true) {
                        self?.applyBackgroundAudio(
                            from: fileURL,
                            displayName: "Recorded Audio",
                            sourceId: UUID().uuidString,
                            source: .recorded
                        )
                    }
                }
            )
        )
    }

    private func presentAudioImportSheet<Content: View>(rootView: Content) {
        let sheetVC = UIHostingController(rootView: rootView)
        sheetVC.modalPresentationStyle = .pageSheet
                if let sheetPresentationController = sheetVC.sheetPresentationController {
                    sheetPresentationController.detents = [.medium(), .large()]
                    sheetPresentationController.prefersGrabberVisible = true
                    sheetPresentationController.preferredCornerRadius = 20
                }
        present(sheetVC, animated: true)
    }

    private func applyBackgroundAudio(
        from fileURL: URL,
        displayName: String,
        sourceId: String,
        source: BackgroundAudioSource
    ) {
        Task {
            let compositionDuration = self.composition?.duration ?? .zero
            _ = await UserDataManager.main.setBackgroundAudioTrack(
                fileURL: fileURL,
                displayName: displayName,
                sourceId: sourceId,
                source: source,
                compositionDuration: compositionDuration
            )
            await self.reloadComposition()
            await MainActor.run {
                self.audioSectionVC.configure(
                    track: UserDataManager.main.backgroundAudioTrack,
                    compositionDuration: self.composition?.duration ?? .zero,
                    timelineAsset: self.spidPlayerController?.player?.currentItem?.asset
                )
                self.presentSourceAudioTrimmer()
            }
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
            guard let self = self else { return }
            Task {
                await UserDataManager.main.currentSpidAsset.updateTimeRange(timeRange: timeRange)
                await self.reloadComposition()
                await self.textSectionVC.createTrimmerView()
                let startTime = self.getStartTimeForCurrentSpidAsset()
                await self.spidPlayerController?.player?.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
                self.spidPlayerController?.player?.play()
            }
        }
    
        // this call to view,in turn, invokes the viewDidLoad method
        let _ = trimmerSectionVC.view
    }

    func createSplitSection() {
        splitSectionVC = SplitSectionVC()
        splitSectionVC.delegate = self

        splitSectionVC.splitConfirmed = { [weak self] splitTime in
            guard let self else { return }
            Task {
                let didSplit = await UserDataManager.main.splitCurrentAsset(at: splitTime)
                guard didSplit else {
                    await self.splitSectionVC.reloadTimelineFromOutside()
                    return
                }
                await self.reloadComposition()
                await MainActor.run {
                    self.videosCollectionView.reloadData()
                    self.updateTrashVisibility()
                }
                NotificationCenter.default.post(name: Notification.Name.VideoSelectionChanged, object: nil)
                let startTime = self.getStartTimeForCurrentSpidAsset()
                await self.spidPlayerController?.player?.seek(
                    to: startTime,
                    toleranceBefore: .zero,
                    toleranceAfter: .zero
                )
                self.spidPlayerController?.player?.play()
                await self.splitSectionVC.reloadTimelineFromOutside()
            }
        }

        let _ = splitSectionVC.view
    }

    func createFilterSection() {
        filterSectionVC = FilterSectionVC()
        filterSectionVC.filterDidChange = { [weak self] filter in
            guard let self else { return }
            Task {
                await UserDataManager.main.currentSpidAsset.updateVideoFilter(filter)
                await self.reloadComposition()
                let startTime = self.getStartTimeForCurrentSpidAsset()
                await self.spidPlayerController?.player?.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
                self.spidPlayerController?.player?.play()
            }
        }

        filterSectionVC.applyToAllTapped = { [weak self] filter in
            guard let self else { return }
            Task {
                for spidAsset in UserDataManager.main.spidAssets {
                    await spidAsset.updateVideoFilter(filter)
                }
                await self.reloadComposition()
                let startTime = self.getStartTimeForCurrentSpidAsset()
                await self.spidPlayerController?.player?.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
                self.spidPlayerController?.player?.play()
            }
        }

        let _ = filterSectionVC.view
    }
    
    func createTextSection() {
        textSectionVC = TextSectionVC()
        textSectionVC.view.frame = dashboardContainerView.bounds

        textSectionVC.delegate = self

        let _ = textSectionVC.view
    }
    
    func createCaptionsSection()  {
        // Prepare captions
        var captions: [CaptionItem] = []
        
        captionsSectionVC = CaptionsSectionVC()
        captionsViewModel = CaptionsViewModel(captions: CaptionItem.generatePreviewCaptions())
        captionsViewModel.$lastEditedCaption.sink { captionItem in
            if let caption = captionItem {
                   print("UIKit got edit event for: \(caption.text)")
            }
        }.store(in: &subscribers)
        
        captionsSectionVC.viewModel = captionsViewModel
        captionsSectionVC.editStyleTapped = { [weak self] in
            guard let self = self else { return }

            let sheetVC = UIHostingController(rootView: CaptionsStyleSheetView())
            sheetVC.modalPresentationStyle = .pageSheet
            
            if let sheetPresentationController = sheetVC.sheetPresentationController {
                sheetPresentationController.detents = [.medium()]
                sheetPresentationController.prefersGrabberVisible = true
                sheetPresentationController.preferredCornerRadius = 20
            }
            
            self.present(sheetVC, animated: true)
        }
        captionsSectionVC.generateCaptionsTapped = { [weak self] in
            self?.presentCaptionsSettingsView()
        }
    
    }
    
    // MARK: Adding Sections
    func addTimingSection() {
        Task {
            guard let currentSpidAsset = UserDataManager.main.currentSpidAsset else { return }
            let isImage = await currentSpidAsset.isImageClip
            await MainActor.run {
                if isImage {
                    addImageDurationSection()
                } else {
                    addSpeedSection()
                }
                refreshCurrentClipMenuState()
            }
        }
    }

    func addSpeedSection() {
        addSection(sectionVC: speedSectionVC)
        currentShownSection = speedSectionVC
    }

    func addImageDurationSection() {
        addSection(sectionVC: imageDurationSectionVC)
        currentShownSection = imageDurationSectionVC
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

    func addAudioSection() {
        addSection(sectionVC: audioSectionVC)
        currentShownSection = audioSectionVC
        audioSectionVC.configure(
            track: UserDataManager.main.backgroundAudioTrack,
            compositionDuration: composition?.duration ?? .zero,
            timelineAsset: spidPlayerController?.player?.currentItem?.asset
        )
    }
    
    func addFiletypeSection() {
        addSection(sectionVC: moreSectionVC)
        currentShownSection = moreSectionVC

    }
    
    func addTrimmerSection() {
        addSection(sectionVC: trimmerSectionVC)
        currentShownSection = trimmerSectionVC
    }

    func addSplitSection() {
        addSection(sectionVC: splitSectionVC)
        currentShownSection = splitSectionVC
        Task {
            await splitSectionVC.reloadTimelineFromOutside()
        }
    }

    func addFilterSection() {
        addSection(sectionVC: filterSectionVC)
        currentShownSection = filterSectionVC
        Task {
            await filterSectionVC.reloadFromCurrentAsset()
        }
    }

    func addTextSection() {
        addSection(sectionVC: textSectionVC)
        currentShownSection = textSectionVC
    }
    
    func addCaptionsSection()  {
        addSection(sectionVC: captionsSectionVC)
        currentShownSection = captionsSectionVC
    }

    func formatDurationLabel(_ seconds: Double) -> String {
        if seconds.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(seconds))s"
        }
        return String(format: "%.1fs", seconds)
    }

    func refreshCurrentClipMenuState() {
        Task {
            guard let spidAsset = UserDataManager.main.currentSpidAsset else { return }
            let isImage = await spidAsset.isImageClip
            let labelText: String
            if isImage {
                labelText = formatDurationLabel(await spidAsset.timeRange.duration.seconds)
            } else {
                labelText = "\(await spidAsset.speed)x"
            }
            await MainActor.run {
                self.showsDurationSectionForCurrentClip = isImage
                self.speedLabel?.text = labelText
                self.bottomMenuCollectionView?.reloadData()
            }
        }
    }
}

extension EditViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.spidPlayerController?.player?.play()
    }
}
