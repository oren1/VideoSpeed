//
//  ProjectMediaStore.swift
//  VideoSpeed
//

import Foundation

/// Materializes video bytes stored on `SpidAssetModel.videoData` into a cache file so
/// AVFoundation (which needs a file URL) can play them back. Files here are disposable —
/// the source of truth is the `Data` persisted in SwiftData.
enum ProjectMediaStore {
    private static let folderName = "SpidMediaCache"

    static var rootURL: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent(folderName, isDirectory: true)
    }

    static func cacheFileURL(forAssetID id: UUID, fileExtension: String = "mov") -> URL {
        let ext = fileExtension.isEmpty ? "mov" : fileExtension
        return rootURL.appendingPathComponent(id.uuidString).appendingPathExtension(ext)
    }

    /// Writes `data` to a stable cache file (reusing it if already present) and returns its URL.
    static func materialize(_ data: Data, assetID: UUID, fileExtension: String) throws -> URL {
        try ensureRootExists()
        let destination = cacheFileURL(forAssetID: assetID, fileExtension: fileExtension)

        if let attrs = try? FileManager.default.attributesOfItem(atPath: destination.path),
           let size = attrs[.size] as? NSNumber,
           size.int64Value == Int64(data.count) {
            return destination
        }

        try data.write(to: destination, options: .atomic)
        return destination
    }

    static func removeFile(forAssetID id: UUID) {
        let url = cacheFileURL(forAssetID: id)
        try? FileManager.default.removeItem(at: url)
    }

    static func removeFiles(forAssetIDs ids: [UUID]) {
        ids.forEach(removeFile(forAssetID:))
    }

    // MARK: - Private

    private static func ensureRootExists() throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: rootURL.path) {
            try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        }
    }
}
