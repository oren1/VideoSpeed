//
//  VideoLibraryPickerPresenter.swift
//  VideoSpeed
//

import PhotosUI
import UIKit
import UniformTypeIdentifiers

final class VideoLibraryPickerPresenter: NSObject {
    private var onPick: ((URL, String) -> Void)?
    private var onCancel: (() -> Void)?

    func present(
        from viewController: UIViewController,
        onPick: @escaping (URL, String) -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        self.onPick = onPick
        self.onCancel = onCancel

        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .videos
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        viewController.present(picker, animated: true)
    }
}

extension VideoLibraryPickerPresenter: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let result = results.first else {
            picker.dismiss(animated: true) { [weak self] in
                self?.onCancel?()
                self?.clearHandlers()
            }
            return
        }

        let suggestedName = result.itemProvider.suggestedName ?? "Video"

        result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
            guard let self, let url, error == nil else {
                DispatchQueue.main.async {
                    picker.dismiss(animated: true) {
                        self?.onCancel?()
                        self?.clearHandlers()
                    }
                }
                return
            }

            let destinationURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("picked-video-\(UUID().uuidString)")
                .appendingPathExtension(url.pathExtension.isEmpty ? "mov" : url.pathExtension)

            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: url, to: destinationURL)
                DispatchQueue.main.async {
                    picker.dismiss(animated: true) {
                        self.onPick?(destinationURL, suggestedName)
                        self.clearHandlers()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    picker.dismiss(animated: true) {
                        self.onCancel?()
                        self.clearHandlers()
                    }
                }
            }
        }
    }

    private func clearHandlers() {
        onPick = nil
        onCancel = nil
    }
}
