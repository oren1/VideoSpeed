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
    /// Composition frame rate used in the editor / export (default 30).
    var fps: Int = 30
    @Relationship(deleteRule: .cascade, inverse: \SpidAssetModel.project)
    var spidAssets: [SpidAssetModel] = []
    @Relationship(deleteRule: .cascade, inverse: \SDLabelViewModel.project)
    var labelViewModels: [SDLabelViewModel] = []
    @Relationship(deleteRule: .cascade, inverse: \SDCaptions.project)
    var captions: SDCaptions?
    @Relationship(deleteRule: .cascade, inverse: \SDBackgroundAudio.project)
    var backgroundAudio: SDBackgroundAudio?

    init(
        thumbnailImage: Data = Data(),
        createdAt: Date = Date(),
        fps: Int = 30,
        spidAssets: [SpidAssetModel] = [],
        labelViewModels: [SDLabelViewModel] = [],
        captions: SDCaptions? = nil,
        backgroundAudio: SDBackgroundAudio? = nil
    ) {
        self.thumbnailImage = thumbnailImage
        self.createdAt = createdAt
        self.fps = fps
        self.spidAssets = spidAssets
        self.labelViewModels = labelViewModels
        self.captions = captions
        self.backgroundAudio = backgroundAudio
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
