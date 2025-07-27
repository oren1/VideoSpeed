//
//  AVMutableComposition+Extension.swift
//  VideoSpeed
//
//  Created by oren shalev on 14/06/2025.
//

import Foundation
import AVFoundation

extension AVMutableComposition {
    static func createCompositionWith(spidAsset: SpidAsset) async -> AVMutableComposition {
        
        let composition = AVMutableComposition(urlAssetInitializationOptions: nil)
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: 1)!
        let (asset, timeRange, speed, soundOn) = await (spidAsset.getAsset(), spidAsset.timeRange, spidAsset.speed, spidAsset.soundOn)
        
        if let audioTracks = try? await asset.loadTracks(withMediaType: .audio),
           soundOn && audioTracks.count > 0 {
            let audioTrack = audioTracks[0]
            let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: 2)!
            let audioDuration = try! await asset.load(.duration)
            
            try? compositionAudioTrack.insertTimeRange(timeRange,
                                                       of: audioTrack,
                                                       at: CMTime.invalid)
        }
        
        
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first,
              let videoDuration = try? await asset.load(.duration),
              let naturalSize = try? await videoTrack.load(.naturalSize),
              let preferredTransform = try? await videoTrack.load(.preferredTransform) else {return composition}
        
        
        try? compositionVideoTrack.insertTimeRange(timeRange,
                                                   of: videoTrack,
                                                   at: CMTime.invalid)
        
        
        
        guard let compositionOriginalDuration = try? await composition.load(.duration) else {return composition}
        let newDuration = Int64(compositionOriginalDuration.seconds / Double(speed))
        composition.scaleTimeRange(CMTimeRange(start: .zero, duration: compositionOriginalDuration), toDuration: CMTime(value: newDuration, timescale: 1))

        compositionVideoTrack.preferredTransform = preferredTransform
     
        return composition
    }

}
