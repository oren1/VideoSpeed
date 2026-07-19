//
//  RecordAudioView.swift
//  VideoSpeed
//

import SwiftUI
import AVFoundation
import Combine

@MainActor
final class RecordAudioViewModel: NSObject, ObservableObject {
    enum Phase {
        case idle
        case recording
        case preview
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var elapsedSeconds: TimeInterval = 0
    @Published var permissionDeniedAlert = false
    @Published var errorMessage: String?

    private var recorder: AVAudioRecorder?
    private var recordedFileURL: URL?
    private var elapsedTimer: Timer?
    private var recordingStartedAt: Date?

    var formattedElapsed: String {
        let total = Int(elapsedSeconds)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var hasRecording: Bool {
        recordedFileURL != nil && phase == .preview
    }

    func toggleRecord() {
        switch phase {
        case .idle, .preview:
            requestPermissionAndStart()
        case .recording:
            stopRecording(keepFile: true)
        }
    }

    func reRecord() {
        discardRecordingFile()
        elapsedSeconds = 0
        phase = .idle
        requestPermissionAndStart()
    }

    func takeRecordingURL() -> URL? {
        guard phase == .preview else { return nil }
        let url = recordedFileURL
        recordedFileURL = nil
        return url
    }

    func cancel() {
        if phase == .recording {
            stopRecording(keepFile: false)
        } else {
            discardRecordingFile()
            tearDownSession()
        }
    }

    private func requestPermissionAndStart() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }
                if granted {
                    self.startRecording()
                } else {
                    self.permissionDeniedAlert = true
                }
            }
        }
    }

    private func startRecording() {
        do {
            discardRecordingFile()

            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("recorded-audio-\(UUID().uuidString)")
                .appendingPathExtension("m4a")

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let recorder = try AVAudioRecorder(url: outputURL, settings: settings)
            recorder.delegate = self
            guard recorder.record() else {
                errorMessage = "Could not start recording."
                tearDownSession()
                return
            }

            self.recorder = recorder
            recordedFileURL = outputURL
            recordingStartedAt = Date()
            elapsedSeconds = 0
            phase = .recording
            startElapsedTimer()
        } catch {
            errorMessage = error.localizedDescription
            tearDownSession()
            phase = .idle
        }
    }

    private func stopRecording(keepFile: Bool) {
        stopElapsedTimer()
        recorder?.stop()
        recorder = nil

        if keepFile, let recordedFileURL,
           FileManager.default.fileExists(atPath: recordedFileURL.path),
           elapsedSeconds > 0.2 {
            phase = .preview
        } else {
            discardRecordingFile()
            elapsedSeconds = 0
            phase = .idle
        }
        tearDownSession()
    }

    private func startElapsedTimer() {
        stopElapsedTimer()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let started = self.recordingStartedAt else { return }
                self.elapsedSeconds = Date().timeIntervalSince(started)
            }
        }
    }

    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    private func discardRecordingFile() {
        if let recordedFileURL,
           FileManager.default.fileExists(atPath: recordedFileURL.path) {
            try? FileManager.default.removeItem(at: recordedFileURL)
        }
        recordedFileURL = nil
    }

    private func tearDownSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

extension RecordAudioViewModel: AVAudioRecorderDelegate {
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.errorMessage = error?.localizedDescription ?? "Recording failed."
            self.stopRecording(keepFile: false)
        }
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            guard self.phase == .recording else { return }
            if flag {
                self.stopElapsedTimer()
                self.recorder = nil
                if self.elapsedSeconds > 0.2 {
                    self.phase = .preview
                } else {
                    self.discardRecordingFile()
                    self.elapsedSeconds = 0
                    self.phase = .idle
                }
                self.tearDownSession()
            } else {
                self.stopRecording(keepFile: false)
                self.errorMessage = "Recording did not complete successfully."
            }
        }
    }
}

struct RecordAudioView: View {
    let onCancel: () -> Void
    let onComplete: (URL) -> Void

    @StateObject private var viewModel = RecordAudioViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(viewModel.formattedElapsed)
                    .font(.system(size: 44, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .padding(.top, 32)

                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button(action: { viewModel.toggleRecord() }) {
                    ZStack {
                        Circle()
                            .fill(viewModel.phase == .recording ? Color.red.opacity(0.2) : Color.secondary.opacity(0.15))
                            .frame(width: 96, height: 96)

                        if viewModel.phase == .recording {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red)
                                .frame(width: 28, height: 28)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.red)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.phase == .recording ? "Stop recording" : "Start recording")

                if viewModel.phase == .preview {
                    HStack(spacing: 16) {
                        Button("Re-record") {
                            viewModel.reRecord()
                        }
                        .buttonStyle(.bordered)

                        Button("Use Recording") {
                            if let url = viewModel.takeRecordingURL() {
                                onComplete(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 8)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        viewModel.cancel()
                        onCancel()
                    }
                }
            }
            .alert("Microphone Access Needed", isPresented: $viewModel.permissionDeniedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enable microphone access in Settings to record background audio.")
            }
            .alert(
                "Could Not Record",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var statusText: String {
        switch viewModel.phase {
        case .idle:
            return "Tap the mic to start recording"
        case .recording:
            return "Recording… tap stop when done"
        case .preview:
            return "Review your recording, then use it"
        }
    }
}

#Preview {
    RecordAudioView(onCancel: {}, onComplete: { _ in })
}
