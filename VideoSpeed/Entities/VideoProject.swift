//
//  VideoProject.swift
//  VideoSpeed
//

import Foundation
import SwiftData
import UIKit

@Model
final class VideoProject {
//    var speed: Float
    var thumbnailImage: Data
    @Relationship(deleteRule: .cascade, inverse: \SpidAssetModel.project)
    var spidAssets: [SpidAssetModel]

    init(
//        speed: Float = 1.0,
        thumbnailImage: Data = Data(),
        spidAssets: [SpidAssetModel] = []
    ) {
//        self.speed = speed
        self.thumbnailImage = thumbnailImage
        self.spidAssets = spidAssets
    }

    var thumbnailCGImage: CGImage? {
        guard !thumbnailImage.isEmpty,
              let uiImage = UIImage(data: thumbnailImage) else { return nil }
        return uiImage.cgImage
    }
}
