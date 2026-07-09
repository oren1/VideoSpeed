//
//  ExtractAudioFromVideoView.swift
//  VideoSpeed
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ExtractAudioFromVideoView: View {
    let onAudioExtracted: (URL, String) -> Void
    let onCancel: () -> Void

    @State private var selectedVideoURL: URL?
    @State private var selectedVideoName: String?
    @State private var isShowingPicker = false
    @State private var isExtracting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "film")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                Text("Choose a video from your library. Its audio track will be used as background audio.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let selectedVideoName {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(selectedVideoName)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(2)
                        Spacer()
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    isShowingPicker = true
                } label: {
                    Label(
                        selectedVideoURL == nil ? "Choose Video" : "Choose Another Video",
                        systemImage: "photo.on.rectangle"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)

                Button {
                    extractAudio()
                } label: {
                    Group {
                        if isExtracting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Use Audio")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedVideoURL == nil || isExtracting)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Extract from Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                        .disabled(isExtracting)
                }
            }
            .sheet(isPresented: $isShowingPicker) {
                VideoLibraryPicker { url, name in
                    selectedVideoURL = url
                    selectedVideoName = name
                    errorMessage = nil
                    isShowingPicker = false
                } onCancel: {
                    isShowingPicker = false
                }
            }
        }
    }

    private func extractAudio() {
        guard let selectedVideoURL else { return }
        isExtracting = true
        errorMessage = nil

        Task {
            do {
                let audioURL = try await AudioExtractor.extractAudio(from: selectedVideoURL)
                let displayName = selectedVideoName ?? "Extracted Audio"
                await MainActor.run {
                    isExtracting = false
                    onAudioExtracted(audioURL, displayName)
                }
            } catch {
                await MainActor.run {
                    isExtracting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

private struct VideoLibraryPicker: UIViewControllerRepresentable {
    let onPick: (URL, String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .videos
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (URL, String) -> Void
        let onCancel: () -> Void

        init(onPick: @escaping (URL, String) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                onCancel()
                return
            }

            let suggestedName = result.itemProvider.suggestedName ?? "Video"

            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                guard let url, error == nil else {
                    DispatchQueue.main.async { self.onCancel() }
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
                        self.onPick(destinationURL, suggestedName)
                    }
                } catch {
                    DispatchQueue.main.async { self.onCancel() }
                }
            }
        }
    }
}

#Preview {
    ExtractAudioFromVideoView(
        onAudioExtracted: { _, _ in },
        onCancel: {}
    )
}
