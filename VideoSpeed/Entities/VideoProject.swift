//
//  VideoProject.swift
//  VideoSpeed
//

import Foundation
import SwiftData
import UIKit

@Model
final class VideoProject {
    var thumbnailImage: Data = Data()
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \SpidAssetModel.project)
    var spidAssets: [SpidAssetModel] = []

    init(
        thumbnailImage: Data = Data(),
        createdAt: Date = Date(),
        spidAssets: [SpidAssetModel] = []
    ) {
        self.thumbnailImage = thumbnailImage
        self.createdAt = createdAt
        self.spidAssets = spidAssets
    }

    var thumbnailCGImage: CGImage? {
        guard !thumbnailImage.isEmpty,
              let uiImage = UIImage(data: thumbnailImage) else { return nil }
        return uiImage.cgImage
    }
}
