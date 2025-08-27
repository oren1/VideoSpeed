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

         
      cell.titleLabel.text = item.title
      cell.imageView.image = UIImage(systemName: item.imageName)

      return cell
    }
}

extension EditViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let menuItem = menuItems[indexPath.row]
        selectedMenuItem = menuItem
        if menuItem.id != .crop {
            removeCropVCFromTop()
        }
        
        currentShownSection.remove()
        
        switch menuItem.id {
        case .speed:
            addSpeedSection()
        case .trim:
            addTrimmerSection()
        case .crop:
            addCropSection()
            addCropViewControllerToTop()
        case .fps:
            addFPSSection()
        case .sound:
            addSoundSection()
        case .text:
            addTextSection()
        case .more:
            addFiletypeSection()
        case .captions:
            addCaptionsSection()
            
           
            if UserDataManager.main.userDontHaveCaptionsYet() {
                presentCaptionsSettingsView()
            }
           
        }
        
        videosMenuDelegate.selectedMenuItem = selectedMenuItem
        if selectedMenuItem.id == .fps ||
            selectedMenuItem.id == .more ||
            selectedMenuItem.id == .text {
            showEntireVideoEditIndication()
        }
        else {
            showSingleVideoEditIndication()
        }
        
        collectionView.reloadData()
        videosCollectionView.reloadData()
    }
    
    func presentCaptionsSettingsView() {
        let captionsSettingsSelectionView = CaptionsSettingsSelectionView { languageItem in
            /* this callback is called when the user tapped on the 'generate captions' button
             so here the transcribing process starts */
            print("languageItem \(languageItem)")
            // open the 'CaptionsSettingsSelectionView' in case there aren't any captions generated
            Task {
                let status = await SpeechRecognizer.getSpeechRecognitionPermissionsStatus()
                if status == .authorized {
                    // start the speech recognition process
                    // 1. grab the avasset from the playerItem
                    let asset = self.spidPlayerController.player.currentItem!.asset
                    let audioURL = FileManager.default.temporaryDirectory
                               .appendingPathComponent(UUID().uuidString)
                               .appendingPathExtension("m4a")
                    let resultURL = try? await SpeechRecognizer.exportAudio(from: asset, to: audioURL)
//                      let resultURL = Bundle.main.url(forResource: "test", withExtension: "m4a")
                    if resultURL != nil {
                        // Initialize WhisperKit with default settings
                        // WhisperKitConfig(model: "base")
                        // Find your models inside the bundle
                        let modelURL = Bundle.main.bundleURL.appendingPathComponent("openai_whisper-base")
                        print("modelURL: \(modelURL)")
                        let config = WhisperKitConfig(model: modelURL.path)

                        // Initialize
                        
                        
                        
                        do {
                            let pipe = try await WhisperKit(config)
                        } catch  {
                            print("error \(error)")
                        }
//                        let pipe = try? await WhisperKit(WhisperKitConfig(model: "base"))
                    
//                        if let transcriptionResult = try? await pipe!.transcribe(audioPath: resultURL!.path)[0] {
//                            for segment in transcriptionResult.segments {
//                                print("segment.substring \(segment.words?[0].word)")
//                            }
////                            print("transcriptionResult \(transcriptionResult)")
//                        }
                    }
                           
//                           let transcription = try? await pipe!.transcribe(audioPath: "path/to/your/audio.{wav,mp3,m4a,flac}")?.text
                        
//                        if let segments = try? await SpeechRecognizer.transcribeAudio(url: resultURL!) {
//                            for segment in segments {
//                                print("segment.substring \(segment.substring): \(segment.timestamp), \(segment.duration)")
//                            }
//                            
//                           let sentences = SpeechRecognizer.groupSegmentsIntoSentences(segments: segments)
//                            for sentence in sentences {
//                                print("sentence: \(sentence.text)")
//                            }
//                        }
                        
                }
                else {
                    print ("Speech recognition not authorized")
                }
            }
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
