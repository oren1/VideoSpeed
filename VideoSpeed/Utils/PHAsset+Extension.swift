//
//  PHAsset+Extension.swift
//  VideoSpeed
//
//  Created by oren shalev on 15/07/2023.
//

import Foundation
import Photos
typealias PHAssetVideoProgressHandler = (Double, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable : Any]?) -> Void

extension PHAsset {
    
    func getAVAssetUrl(progressHandler: PHAssetVideoProgressHandler?, completionHandler : @escaping ((_ responseURL : URL?) -> Void)){
               let options: PHVideoRequestOptions = PHVideoRequestOptions()
               options.deliveryMode = .highQualityFormat
               options.isNetworkAccessAllowed = true
               options.progressHandler = progressHandler
        
               PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable : Any]?) -> Void in
                   if let urlAsset = asset as? AVURLAsset {
                            let localVideoUrl: URL = urlAsset.url as URL
                                completionHandler(localVideoUrl)
                            } else {
                                completionHandler(nil)
                            }
               })
           
       }
}
