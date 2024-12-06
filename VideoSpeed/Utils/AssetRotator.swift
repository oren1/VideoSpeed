//
//  AssetRotator.swift
//  VideoSpeed
//
//  Created by oren shalev on 05/12/2024.
//

import AVFoundation

class AssetRotator {
    
    @Published var assetRotated = false
    @Published var progress: Float = 0
    var asset: AVAsset
    var exportSession: AVAssetExportSession!
    var timer: Timer?
    init(asset: AVAsset) {
        self.asset = asset
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let progress = self?.exportSession?.progress else { return }
            self?.progress = progress
            print("progress: ",progress)
        }
    }
    
    func rotateVideoToIntendedOrientation() async -> AVAsset {
        // Check if the video is shown in the intended orientation
        
        guard let videoTrack = try? await self.asset.loadTracks(withMediaType: .video).first,
              let duration = try? await self.asset.load(.duration),
              let nominalFrameRate = try? await videoTrack.load(.nominalFrameRate),
              let naturalSize = try? await videoTrack.load(.naturalSize),
              let preferredTransform = try? await videoTrack.load(.preferredTransform) else {return self.asset}
        
        let videoInfo = VideoHelper.orientation(from: preferredTransform)

        guard videoInfo.isPortrait else { return self.asset }
        let videoSize = CGSize(width: naturalSize.height,height: naturalSize.width)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
        
        let layerInstruction = await compositionLayerInstruction(for: videoTrack, videoSize: videoSize)
        instruction.layerInstructions = [layerInstruction]
       
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [instruction]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: Int32(ceilf(nominalFrameRate)))
        videoComposition
            .renderSize = CGSize(width: videoSize.width, height: videoSize.height)
       
        exportSession = AVAssetExportSession(asset: self.asset,presetName: AVAssetExportPresetHighestQuality)
        guard exportSession != nil else {
            print("Cannot create export session.")
            return self.asset
        }
        
        let videoName = UUID().uuidString
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
          .appendingPathComponent(videoName)
          .appendingPathExtension("mov")
        
        exportSession.videoComposition = videoComposition
        exportSession.outputFileType = .mov
        exportSession.outputURL = exportURL

        await exportSession.export()
        
        switch exportSession.status {
        case .completed:
          print("completed export with url: \(exportURL)")
            assetRotated = true
            return AVURLAsset(url: exportURL)
               
        default:
            return self.asset
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
