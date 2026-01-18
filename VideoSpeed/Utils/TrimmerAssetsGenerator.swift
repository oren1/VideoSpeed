//
//  TrimmerAssetsGenerator.swift
//  VideoSpeed
//
//  Created by oren shalev on 10/06/2025.
//

import Foundation
import AVFoundation
import UIKit

class TrimmerAssetsGenerator {
    let trimmerWidth: CGFloat
    let trimmerHeight: CGFloat
    let asset: AVAsset
    let generator: AVAssetImageGenerator
    
    init(asset: AVAsset, videoComposition: AVVideoComposition? = nil, trimmerWidth: CGFloat, trimmerHeight: CGFloat) {
        self.trimmerWidth = trimmerWidth
        self.trimmerHeight = trimmerHeight
        self.asset = asset
        generator = AVAssetImageGenerator(asset: asset)
        generator.videoComposition = videoComposition
        generator.appliesPreferredTrackTransform = true
    }
    
    
    func generateThumbnailImages() async -> [CGImage]? {
        guard let thumbnailSize = getThumbnailSize() else {
            print("no thumbnail size")
            return nil
        }
        let scaledSize = await CGSize(width: thumbnailSize.width * UIScreen.main.scale, height: thumbnailSize.height * UIScreen.main.scale)
        generator.maximumSize = scaledSize
        let visibleThumbnailsCount = Int(ceil(trimmerWidth / thumbnailSize.width))
        print("visibleThumbnailsCount: \(visibleThumbnailsCount)")
        let thumbnailTimes = getThumbnailTimes(numberOfThumbnails: visibleThumbnailsCount)
        
        let images = await generateImagesFor(times: thumbnailTimes)
        return images
    }
    
    
    private func generateImagesFor(times: [NSValue]) async -> [CGImage] {
      
        await withCheckedContinuation { continuation in
            
            var timesCount = times.count
            var images: [CGImage] = []
            
            generator.generateCGImagesAsynchronously(forTimes: times) { _, cgImage, _, result, error in
                if let cgimage = cgImage, error == nil && result == AVAssetImageGenerator.Result.succeeded {
                    images.append(cgimage)
                    if images.count == timesCount {
                        continuation.resume(returning: images)
                    }
                }
            }
        }
       
    }
    
    
    private func getThumbnailSize() -> CGSize? {
        guard let track = asset.tracks(withMediaType: AVMediaType.video).first else { return nil}

        let assetSize = track.naturalSize.applying(track.preferredTransform)
        let ratio: CGFloat
        if assetSize.orientation() == .landscape {
            ratio = 3/4
        }
        else {
            ratio = assetSize.width / assetSize.height
        }
        let width = trimmerHeight * ratio
//        return CGSize(width: abs(width), height: abs(trimmerHeight))
        return CGSize(width: abs(width), height: abs(trimmerHeight))

    }
    
    
    private func getThumbnailTimes(numberOfThumbnails: Int) -> [NSValue] {
        let timeIncrement = (asset.duration.seconds * 1000) / Double(numberOfThumbnails)
        var timesForThumbnails = [NSValue]()
        for index in 0..<numberOfThumbnails {
            let cmTime = CMTime(value: Int64(timeIncrement * Float64(index)), timescale: 1000)
            let nsValue = NSValue(time: cmTime)
            timesForThumbnails.append(nsValue)
        }
        return timesForThumbnails
    }

    
    
}
