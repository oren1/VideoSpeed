//
//  PHAsset+Extension.swift
//  VideoSpeed
//
//  Created by oren shalev on 15/07/2023.
//

import Foundation
import Photos
import UIKit
typealias PHAssetVideoProgressHandler = (Double, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable : Any]?) -> Void

extension PHAsset {
    
    func getAVAssetUrl(progressHandler: PHAssetVideoProgressHandler?, completionHandler : @escaping ((_ responseURL : URL?, _ asset: AVAsset?) -> Void)){
               let options: PHVideoRequestOptions = PHVideoRequestOptions()
               options.deliveryMode = .highQualityFormat
               options.isNetworkAccessAllowed = true
               options.progressHandler = progressHandler
        
               PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                   if let urlAsset = asset as? AVURLAsset {
                            let localVideoUrl: URL = urlAsset.url as URL
                       completionHandler(localVideoUrl, asset)
                            } else {
                                completionHandler(nil,nil)
                            }
               })
           
       }
    
    func getAVAsset(completion: @escaping () -> ()) async -> AVAsset? {
        let options: PHVideoRequestOptions = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
 
        return await withCheckedContinuation { continuation in
            
            PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                completion()
                continuation.resume(returning: asset)
            })
            
        }
        
    }

    func getFullSizeImage(completion: @escaping () -> Void) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            PHImageManager.default().requestImage(
                for: self,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                completion()
                continuation.resume(returning: image)
            }
        }
    }
}
