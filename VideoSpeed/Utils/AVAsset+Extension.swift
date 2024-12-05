//
//  AVAsset+Extension.swift
//  VideoSpeed
//
//  Created by oren shalev on 10/11/2024.
//

import AVFoundation

extension AVAsset {
    
    func rotateVideoToIntendedOrientation() async -> AVAsset {
        // Check if the video is shown in the intended orientation
        
        guard let videoTrack = try? await self.loadTracks(withMediaType: .video).first,
              let duration = try? await self.load(.duration),
              let nominalFrameRate = try? await videoTrack.load(.nominalFrameRate),
              let naturalSize = try? await videoTrack.load(.naturalSize),
              let preferredTransform = try? await videoTrack.load(.preferredTransform) else {return self}
        
        let videoInfo = VideoHelper.orientation(from: preferredTransform)

        guard videoInfo.isPortrait else { return self }
        let videoSize = CGSize(width: naturalSize.height,height: naturalSize.width)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        
        let layerInstruction = await compositionLayerInstruction(for: videoTrack, videoSize: videoSize)
        instruction.layerInstructions = [layerInstruction]
       
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [instruction]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(ceilf(nominalFrameRate)))
        videoComposition.renderSize = CGSize(width: videoSize.width, height: videoSize.height)
       
        guard let exportSession = AVAssetExportSession(asset: self,presetName: AVAssetExportPresetHighestQuality) else {
            print("Cannot create export session.")
            return self
        }
    
        
        let videoName = UUID().uuidString
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
          .appendingPathComponent(videoName)
          .appendingPathExtension("mov")
        
        exportSession.videoComposition = videoComposition
        exportSession.outputFileType = .mov
        exportSession.outputURL = exportURL
//        if #available(iOS 18, *) {
//            for await state in exportSession.states(updateInterval: 0.2) {
//                print("state: ", state)
//            }
//        } else {
//            // Fallback on earlier versions
//        }
        
        await exportSession.export()
        
        switch exportSession.status {
        case .completed:
          print("completed export with url: \(exportURL)")
            return AVURLAsset(url: exportURL)
               
        default:
            return self
        }
        
    }
    
    
    private func compositionLayerInstruction(for track: AVAssetTrack, videoSize: CGSize) async -> AVMutableVideoCompositionLayerInstruction {
            
            let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        
            var newTransform = CGAffineTransform(translationX: 0, y: 0)
            newTransform = newTransform.rotated(by: CGFloat(90 * Double.pi / 180))
            newTransform = newTransform.translatedBy(x: 0, y: -videoSize.width)
            instruction.setTransform(newTransform, at: .zero)

            return instruction
    }
}
