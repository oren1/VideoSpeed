//
//  SpidAsset.swift
//  VideoSpeed
//
//  Created by oren shalev on 22/12/2024.
//

import Foundation
import AVFoundation
import UniformTypeIdentifiers // iOS 14+

@available(iOS 14.0, *)
extension UTType {
    static let json = UTType(exportedAs: "public.json")
}


actor SpidAsset {
    var id: UUID
    private var asset: AVAsset
    private var rotatedAsset: AVAsset?
    private(set) var assetHasBeenRotated: Bool = false
    var timeRange: CMTimeRange
    var videoSize: CGSize
    var speed: Float = 1
    var soundOn: Bool = true
    let thumbnailImage: CGImage
    var thumbnailImages: [CGImage]?
    var rightHandleConstraintConstant: CGFloat?
    var leftHandleConstraintConstant: CGFloat?
    var videoRect: CGRect = .zero
    var sliderValue: Float = 19.5
    
    
    private enum CodingKeys: String, CodingKey {
           case id
    }
//    // Encode
//       func encode(to encoder: Encoder) throws {
//           var container = encoder.container(keyedBy: CodingKeys.self)
//           try container.encode(id, forKey: .id)
//       }
//    
//    // Decode
//       init(from decoder: Decoder) throws {
//           let container = try decoder.container(keyedBy: CodingKeys.self)
//           id = try container.decode(UUID.self, forKey: .id)
//           // Note: Actor's init can't be failable here; ensure `name` and `id` are reliable
//       }
    
    init(asset: AVAsset, timeRange: CMTimeRange, videoSize: CGSize, thumnbnailImage: CGImage) {
        self.asset = asset
        self.timeRange = timeRange
        self.videoSize = videoSize
        self.thumbnailImage = thumnbnailImage
        self.id = UUID()
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
    
    func updateRightHandleConstraintConstant(constant: CGFloat) {
        self.rightHandleConstraintConstant = constant
    }
    
    func updateLeftHandleConstraintConstant(constant: CGFloat) {
        self.leftHandleConstraintConstant = constant
    }
    
    func updateVideoRect(_ videoRect: CGRect) {
        self.videoRect = videoRect
    }
    
    func updateSliderValue(value: Float)  {
        self.sliderValue = value
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

//extension SpidAsset: NSItemProviderWriting {
//    static var writableTypeIdentifiersForItemProvider: [String] {
//        return [UTType.json.identifier as String]
//    }
//
//    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completion: @escaping (Data?, Error?) -> Void) async -> Progress? {
//        do {
//            let data = try JSONEncoder().encode(self)
//            completion(data, nil)
//        } catch {
//            completion(nil, error)
//        }
//        return Progress()
//    }
//}
//
//extension SpidAsset: NSItemProviderReading {
//    static var readableTypeIdentifiersForItemProvider: [String] {
//        return [UTType.json.identifier as String]
//    }
//
//    static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> SpidAsset {
//        return try JSONDecoder().decode(SpidAsset.self, from: data)
//    }
//}
