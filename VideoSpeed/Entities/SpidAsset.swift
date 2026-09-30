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

enum MediaKind {
    case video
    case image
}

actor SpidAsset {
    let id: UUID
    private var asset: AVAsset
    private var rotatedAsset: AVAsset?
    private(set) var assetHasBeenRotated: Bool = false
    var timeRange: CMTimeRange
    /// Fixed source bounds for trimmer thumbnails; does not shrink when the user trims.
    var clipSourceRange: CMTimeRange
    var videoSize: CGSize
    var speed: Float = 1
    var soundOn: Bool = true
    private(set) var thumbnailImage: CGImage
    var thumbnailImages: [CGImage]?
    var rightHandleConstraintConstant: CGFloat?
    var leftHandleConstraintConstant: CGFloat?
    var videoRect: CGRect = .zero
    var sliderValue: Float = 19.5
    var videoFilter: VideoFilter = .none
    private(set) var mediaKind: MediaKind = .video

    var isImageClip: Bool { mediaKind == .image }
    
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
    
    init(
        asset: AVAsset,
        timeRange: CMTimeRange,
        videoSize: CGSize,
        thumnbnailImage: CGImage,
        mediaKind: MediaKind = .video,
        clipSourceRange: CMTimeRange? = nil,
        id: UUID = UUID(),
        speed: Float = 1,
        soundOn: Bool = true,
        sliderValue: Float = 19.5,
        videoFilter: VideoFilter = .none,
        videoRect: CGRect = .zero
    ) {
        self.asset = asset
        self.timeRange = timeRange
        self.clipSourceRange = clipSourceRange ?? timeRange
        self.videoSize = videoSize
        self.thumbnailImage = thumnbnailImage
        self.mediaKind = mediaKind
        self.id = id
        self.speed = speed
        self.soundOn = soundOn
        self.sliderValue = sliderValue
        self.videoFilter = videoFilter
        self.videoRect = videoRect
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
        Task{
           let _ = await SwiftDataManager.shared.upsertVideoProject()
        }
    }

    func updateClipSourceRange(_ range: CMTimeRange) {
        clipSourceRange = range
    }
    
    func updateSpeed(speed: Float) {
        self.speed = speed
        Task{
           let _ = await SwiftDataManager.shared.upsertVideoProject()
        }
    }
    
    func videoDuration() -> Double {
        self.timeRange.duration.seconds / Double(speed)
    }
    
    func updateSound(soundOn: Bool)  {
        self.soundOn = soundOn
        Task {
           let _ = await SwiftDataManager.shared.upsertVideoProject()
        }
    }
    
    func updateThumbnailImages(images: [CGImage]?) {
        self.thumbnailImages = images
    }

    func updateThumbnailImage(_ image: CGImage) {
        thumbnailImage = image
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

    func updateVideoFilter(_ filter: VideoFilter) {
        videoFilter = filter
    }

    func updateMediaKind(_ kind: MediaKind) {
        mediaKind = kind
    }

    func updateVideoSize(_ size: CGSize) {
        videoSize = size
    }

    func clearHandleConstraintConstants() {
        rightHandleConstraintConstant = nil
        leftHandleConstraintConstant = nil
    }

    func clearTrimmerHandleConstants() {
        clearHandleConstraintConstants()
        thumbnailImages = nil
    }
    
    /// Inverse of `convertSliderValue`: maps a speed back to the UISlider value.
    static func convertSpeedToSliderValue(speed: Float) -> Float {
        if speed == 0.25 {
            return 5
        }
        if speed < 1 {
            let tenths = Int(round(speed * 10))
            switch tenths {
            case 1: return 1
            case 2: return 3
            case 3: return 5
            case 4: return 7
            case 5: return 9
            case 6: return 11
            case 7: return 13
            case 8: return 15
            case 9: return 17
            default: return 19
            }
        }
        if speed == 1 {
            return 19
        }
        return speed + 19
    }
    
    func duplicate(with timeRange: CMTimeRange, thumbnailImage: CGImage, clipSourceRange: CMTimeRange? = nil) async -> SpidAsset {
        let newAsset = SpidAsset(
            asset: getOriginalAsset(),
            timeRange: timeRange,
            videoSize: videoSize,
            thumnbnailImage: thumbnailImage,
            mediaKind: mediaKind,
            clipSourceRange: clipSourceRange ?? timeRange,
            speed: speed,
            soundOn: soundOn,
            sliderValue: sliderValue,
            videoFilter: videoFilter,
            videoRect: videoRect
        )
        if assetHasBeenRotated, let rotatedAsset {
            await newAsset.updateRotatedAsset(rotatedAsset: rotatedAsset)
        }
        return newAsset
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

extension SpidAsset: Equatable {
    nonisolated static func == (lhs: SpidAsset, rhs: SpidAsset) -> Bool {
        lhs.id == rhs.id
    }
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
