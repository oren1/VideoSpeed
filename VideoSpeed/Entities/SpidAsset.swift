//
//  SpidAsset.swift
//  VideoSpeed
//
//  Created by oren shalev on 22/12/2024.
//

import Foundation
import AVFoundation

actor SpidAsset {
    private var asset: AVAsset
    private var rotatedAsset: AVAsset?
    private(set) var assetHasBeenRotated: Bool = false
    var timeRange: CMTimeRange
    var videoSize: CGSize
    var speed: Float = 1
    var soundOn: Bool = true
    let thumbnailImage: CGImage
    var thumbnailImages: [CGImage]?
    
    init(asset: AVAsset, timeRange: CMTimeRange, videoSize: CGSize, thumnbnailImage: CGImage) {
        self.asset = asset
        self.timeRange = timeRange
        self.videoSize = videoSize
        self.thumbnailImage = thumnbnailImage
    }
    
    func getOriginalAsset() -> AVAsset {
        return asset
    }
    
    func getAsset() -> AVAsset { rotatedAsset != nil ? rotatedAsset! : asset }
    
    func updateRotatedAsset(rotatedAsset: AVAsset) {
        self.rotatedAsset = rotatedAsset
        assetHasBeenRotated = true
    }
    
    func updateTimeRange(timeRange: CMTimeRange) {
        self.timeRange = timeRange
    }
    
    func updateSpeed(speed: Float) {
        self.speed = speed
    }
    
    func videoDuration() -> Double {
        self.timeRange.duration.seconds / Double(speed)
    }
    
    func updateSound(soundOn: Bool)  {
        self.soundOn = soundOn
    }
    
    func updateThumbnailImages(images: [CGImage]?) {
        self.thumbnailImages = images
    }
    
//    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack, videoSize: CGSize, isPortrait: Bool, cropRect: CGRect) async -> AVMutableVideoCompositionLayerInstruction {
//        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
//        
//        let transform = try! await assetTrack.load(.preferredTransform)
//        
//        if isPortrait {
//            var newTransform = CGAffineTransform(translationX: 0, y: 0)
//            newTransform = newTransform.rotated(by: CGFloat(90 * Double.pi / 180))
//            newTransform = newTransform.translatedBy(x: 0, y: -videoSize.width)
//            instruction.setTransform(newTransform, at: .zero)
//            
//        }
//        else {
//            instruction.setCropRectangle(CGRect(x: cropRect.origin.x, y: cropRect.origin.y, width: cropRect.size.width, height: cropRect.size.height), at: .zero)
//            
//            let newTransform = transform.translatedBy(x: -cropRect.origin.x, y: -cropRect.origin.y)
//            instruction.setTransform(newTransform, at: .zero)
//        }
//        
//        return instruction
//    }
}
