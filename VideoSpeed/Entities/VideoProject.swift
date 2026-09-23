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
    @Relationship(deleteRule: .cascade, inverse: \SDLabelViewModel.project)
    var labelViewModels: [SDLabelViewModel] = []
    @Relationship(deleteRule: .cascade, inverse: \SDCaptions.project)
    var captions: SDCaptions?

    init(
        thumbnailImage: Data = Data(),
        createdAt: Date = Date(),
        spidAssets: [SpidAssetModel] = [],
        labelViewModels: [SDLabelViewModel] = [],
        captions: SDCaptions? = nil
    ) {
        self.thumbnailImage = thumbnailImage
        self.createdAt = createdAt
        self.spidAssets = spidAssets
        self.labelViewModels = labelViewModels
        self.captions = captions
    }

    var thumbnailCGImage: CGImage? {
        guard !thumbnailImage.isEmpty,
              let uiImage = UIImage(data: thumbnailImage) else { return nil }
        return uiImage.cgImage
    }

    /// Fresh fetch of this project's assets from the model context, sorted by `sortIndex`.
    var fetchedSpidAssets: [SpidAssetModel] {
        guard let modelContext else { return spidAssets }
        let projectID = persistentModelID
        let descriptor = FetchDescriptor<SpidAssetModel>(
            predicate: #Predicate { asset in
                asset.project?.persistentModelID == projectID
            },
            sortBy: [SortDescriptor(\.sortIndex)]
        )
        return (try? modelContext.fetch(descriptor)) ?? spidAssets
    }
}
