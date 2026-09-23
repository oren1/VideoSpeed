//
//  EditViewController+BottomMenu.swift
//  VideoSpeed
//
//  Created by oren shalev on 26/01/2025.
//

import Foundation
import UIKit
import SwiftUI
import Speech
import WhisperKit
import CoreML

fileprivate let minimumItemWidth = 64.0

extension EditViewController: UICollectionViewDataSource {
     func numberOfSections(in collectionView: UICollectionView) -> Int {
      return 1
    }

     func collectionView(
      _ collectionView: UICollectionView,
      numberOfItemsInSection section: Int
    ) -> Int {
        return self.menuItems.count
    }

     func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      
     let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: menuItemReuseIdentifier,
        for: indexPath
      ) as! MenuItemCell

      
      let item = menuItems[indexPath.row]
      if item == selectedMenuItem {
          cell.backgroundColor = .white
          cell.imageView.tintColor = .black
          cell.titleLabel.textColor = .black
      }
      else {
          cell.backgroundColor = UIColor(red: 0.093, green: 0.093, blue: 0.093, alpha: 1)
          cell.titleLabel.textColor = .white
          cell.imageView.tintColor = .white
      }
      
      cell.layer.cornerRadius = 8

      var title = item.title
      if item.id == .speed && showsDurationSectionForCurrentClip {
          title = "DURATION"
      }
      cell.titleLabel.text = title
      cell.imageView.image = UIImage(systemName: item.imageName)

      return cell
    }
}

extension EditViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let menuItem = menuItems[indexPath.row]
        let previousMenuItem = selectedMenuItem
        selectedMenuItem = menuItem
        if menuItem.id != .crop {
            removeCropVCFromTop()
        }
        
        currentShownSection.remove()
        
        switch menuItem.id {
        case .speed:
            addTimingSection()
        case .trim:
            addTrimmerSection()
        case .split:
            AnalyticsManager.splitMenuItemSelectedEvent()
            addSplitSection()
        case .filter:
            addFilterSection()
        case .crop:
            addCropSection()
            addCropViewControllerToTop()
        case .fps:
            addFPSSection()
        case .sound:
            addSoundSection()
        case .audio:
            addAudioSection()
        case .text:
            AnalyticsManager.textMenuItemSelectedEvent()
            addTextSection()
        case .more:
            addFiletypeSection()
        case .captions:
            AnalyticsManager.captionsMenuItemSelectedEvent()
            addCaptionsSection()
            
           
            if UserDataManager.main.userDontHaveCaptionsYet() {
                presentCaptionsSettingsView()
            }
           
        }
        
        videosMenuDelegate.selectedMenuItem = selectedMenuItem
        if selectedMenuItem.id == .fps ||
            selectedMenuItem.id == .more ||
            selectedMenuItem.id == .text ||
            selectedMenuItem.id == .audio {
            showEntireVideoEditIndication()
        }
        else {
            showSingleVideoEditIndication()
        }
        
        collectionView.reloadData()
        videosCollectionView.reloadData()

        if previousMenuItem?.id == .split, menuItem.id != .split {
            Task {
                await reloadComposition()
                let startTime = getStartTimeForCurrentSpidAsset()
                await spidPlayerController?.player?.seek(
                    to: startTime,
                    toleranceBefore: .zero,
                    toleranceAfter: .zero
                )
            }
        }
    }
    
    func presentCaptionsSettingsView() {
        let captionsSettingsSelectionView = CaptionsSettingsSelectionView { languageItem in
            /* this callback is called when the user tapped on the 'generate captions' button
             so here the transcribing process starts */
            print("languageItem \(languageItem)")
//            if let transcriptionsResponseData = UserDefaults.standard.data(forKey: "transcriptionResponse")  {
//                do {
//                    let transcriptioResponse = try JSONDecoder().decode(TranscriptionResponse.self, from: transcriptionsResponseData)
//                    UserDataManager.main.transcription = Transcription(transcriptionResponse: transcriptioResponse)
//
//                } catch {
//                    print("Error decoding transcription response")
//                }
//            }
//            else {
                // open the 'CaptionsSettingsSelectionView' in case there aren't any captions generated
                        // start the speech recognition process
                        // 1. grab the avasset from the playerItem
                        let asset = self.spidPlayerController.player.currentItem!.asset
                        let audioURL = FileManager.default.temporaryDirectory
                                   .appendingPathComponent(UUID().uuidString)
                                   .appendingPathExtension("m4a")
                        do {
                            let resultURL = try await SpeechRecognizer.exportAudio(from: asset, to: audioURL)
                            AnalyticsManager.captionsAudioExportedSuccessfullyEvent()
                            let apiKey = (Bundle.main.object(forInfoDictionaryKey: "OPEN_AI_API_KEY") as? String)?
                                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                            guard !apiKey.isEmpty, apiKey != "Open AI API Key Here" else {
                                throw NSError(
                                    domain: "OpenAIConfig",
                                    code: 1,
                                    userInfo: [NSLocalizedDescriptionKey: "OPEN_AI_API_KEY is missing from build configuration"]
                                )
                            }
                            AnalyticsManager.captionsOpenAIApiKeyLoadedSuccessfullyEvent()
                            let transcriptionResult = await OpenAIManager.transcribeAudioAsync(fileURL: resultURL, apiKey: apiKey, languageCode: languageItem.code)
                            switch transcriptionResult {
                                case .success(let transcription):
                                AnalyticsManager.captionsSuccessfulTranscriptionEvent()
                                    UserDataManager.main.transcription = transcription
                                    SwiftDataManager.shared.upsertCaptions()
                                    print(transcription.segments!)
                                case .failure(let error):
                                AnalyticsManager.captionsFailedTranscriptionEvent(error: error.localizedDescription)
                                    throw error
                            }
                        } catch {
                            AnalyticsManager.captionsFailedTranscriptionEvent(error: error.localizedDescription)
                            throw error
                        }
//            }
           
        } onClose: { [weak self] in
            guard let self = self else { return }
            captionsSettingsHostingVC?.dismiss(animated: true)
        }

        
        captionsSettingsHostingVC = UIHostingController(rootView: captionsSettingsSelectionView)
        present(captionsSettingsHostingVC!, animated: true)
    }
}

extension EditViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
      _ collectionView: UICollectionView,
      layout collectionViewLayout: UICollectionViewLayout,
      sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
      // 2
        let heightPaddingSpace = sectionInsets.top * 2
        let availableHeight = collectionView.frame.height - heightPaddingSpace
        let availabelWidth = collectionView.frame.width - (sectionInsets.left * CGFloat(menuItems.count + 1))
        let itemWidth = floor(availabelWidth / CGFloat(menuItems.count))
        
        return CGSize(width: max(minimumItemWidth, itemWidth), height: availableHeight)
    
    }

    // 3
    func collectionView(
      _ collectionView: UICollectionView,
      layout collectionViewLayout: UICollectionViewLayout,
      insetForSectionAt section: Int
    ) -> UIEdgeInsets {
      return sectionInsets
    }

    // 4
    func collectionView(
      _ collectionView: UICollectionView,
      layout collectionViewLayout: UICollectionViewLayout,
      minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
      return sectionInsets.left
    }
}
