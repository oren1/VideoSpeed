//
//  MusicLibraryPickerPresenter.swift
//  VideoSpeed
//

import AVFoundation
import MediaPlayer
import UIKit

enum MusicLibraryPickerError: LocalizedError {
    case unavailable
    case noExportableFile
    case copyFailed

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Music library access is required to import songs. Enable it in Settings."
        case .noExportableFile:
            return "This song can’t be imported. Choose a downloaded song from your library (not Apple Music streaming)."
        case .copyFailed:
            return "Could not import the selected song. Please try another track."
        }
    }
}

enum MusicLibraryAudioExporter {
    /// `ipod-library://` URLs are not filesystem files — export via AVAsset, don't use FileManager.copyItem.
    static func export(from assetURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: assetURL)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("music-import-\(UUID().uuidString)")
            .appendingPathExtension("m4a")

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw MusicLibraryPickerError.copyFailed
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        await exportSession.export()

        switch exportSession.status {
        case .completed:
            return outputURL
        case .failed, .cancelled:
            throw MusicLibraryPickerError.copyFailed
        default:
            throw MusicLibraryPickerError.copyFailed
        }
    }
}

final class MusicLibraryPickerPresenter: NSObject {
    private var onPick: ((URL, String) -> Void)?
    private var onCancel: (() -> Void)?
    private var onError: ((Error) -> Void)?

    func present(
        from viewController: UIViewController,
        onPick: @escaping (URL, String) -> Void,
        onCancel: (() -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) {
        self.onPick = onPick
        self.onCancel = onCancel
        self.onError = onError

        let status = MPMediaLibrary.authorizationStatus()
        switch status {
        case .authorized, .restricted:
            presentPicker(from: viewController)
        case .notDetermined:
            MPMediaLibrary.requestAuthorization { [weak self] newStatus in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if newStatus == .authorized || newStatus == .restricted {
                        self.presentPicker(from: viewController)
                    } else {
                        self.onError?(MusicLibraryPickerError.unavailable)
                        self.clearHandlers()
                    }
                }
            }
        case .denied:
            onError?(MusicLibraryPickerError.unavailable)
            clearHandlers()
        @unknown default:
            presentPicker(from: viewController)
        }
    }

    private func presentPicker(from viewController: UIViewController) {
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.delegate = self
        picker.allowsPickingMultipleItems = false
        picker.showsCloudItems = false
        picker.prompt = "Choose a song for background audio"
        viewController.present(picker, animated: true)
    }

    private func clearHandlers() {
        onPick = nil
        onCancel = nil
        onError = nil
    }
}

extension MusicLibraryPickerPresenter: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        guard let item = mediaItemCollection.items.first else {
            mediaPicker.dismiss(animated: true) { [weak self] in
                self?.onCancel?()
                self?.clearHandlers()
            }
            return
        }

        let displayName = item.title?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? "Imported Audio"
        let isCloud = item.isCloudItem
        let hasProtected = item.hasProtectedAsset

        guard let assetURL = item.assetURL else {
            mediaPicker.dismiss(animated: true) { [weak self] in
                self?.onError?(MusicLibraryPickerError.noExportableFile)
                self?.clearHandlers()
            }
            return
        }

        // Hand the ipod-library URL to the host so it can show loading during export.
        mediaPicker.dismiss(animated: true) { [weak self] in
            self?.onPick?(assetURL, displayName)
            self?.clearHandlers()
        }
    }

    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true) { [weak self] in
            self?.onCancel?()
            self?.clearHandlers()
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
