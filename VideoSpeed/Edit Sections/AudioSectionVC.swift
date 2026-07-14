//
//  AudioSectionVC.swift
//  VideoSpeed
//

import UIKit
import AVFoundation

final class AudioSectionVC: SectionViewController {
    var requestAddAudio: VoidClousure?
    var requestEditSource: VoidClousure?
    var timelineRangeDidChange: ((CMTimeRange) -> Void)?

    private let trimmerView = TrimmerView()
    private let sourceLabel = UILabel()
    private let buttonStack = UIStackView()
    private let addAudioButton = UIButton(type: .system)
    private let editSourceButton = UIButton(type: .system)
    private let trimmerHeight = 56.0

    private var currentTrack: BackgroundAudioTrackItem?
    private var compositionDuration: CMTime = .zero
    private var isConfiguring = false

    // #region agent log
    private func agentLog(hypothesisId: String, location: String, message: String, data: [String: Any]) {
        let payload: [String: Any] = [
            "sessionId": "95da35",
            "runId": "ui-handle-snap",
            "hypothesisId": hypothesisId,
            "location": location,
            "message": message,
            "data": data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]
        guard JSONSerialization.isValidJSONObject(payload),
              let jsonData = try? JSONSerialization.data(withJSONObject: payload),
              let jsonLine = String(data: jsonData, encoding: .utf8) else { return }
        let logLine = jsonLine + "\n"
        let logURL = URL(fileURLWithPath: "/Users/orenshalev/Desktop/VideoSpeed/.cursor/debug-95da35.log")
        if FileManager.default.fileExists(atPath: logURL.path) {
            if let handle = try? FileHandle(forWritingTo: logURL) {
                try? handle.seekToEnd()
                try? handle.write(contentsOf: Data(logLine.utf8))
                try? handle.close()
            }
        } else {
            try? Data(logLine.utf8).write(to: logURL, options: .atomic)
        }
    }
    // #endregion

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func configure(track: BackgroundAudioTrackItem?, compositionDuration: CMTime, timelineAsset: AVAsset?) {
        // #region agent log
        agentLog(
            hypothesisId: "H1",
            location: "AudioSectionVC.configure:entry",
            message: "configure called",
            data: [
                "hasTrack": track != nil,
                "compositionDuration": compositionDuration.seconds,
                "timelineAssetDuration": timelineAsset?.duration.seconds ?? -1,
                "timelineAssetNil": timelineAsset == nil
            ]
        )
        // #endregion
        self.currentTrack = track
        self.compositionDuration = compositionDuration
        isConfiguring = true
        defer { isConfiguring = false }

        let hasTrack = track != nil
        trimmerView.isHidden = !hasTrack
        trimmerView.isUserInteractionEnabled = hasTrack
        trimmerView.alpha = hasTrack ? 1 : 0.4
        sourceLabel.isHidden = !hasTrack
        editSourceButton.isEnabled = hasTrack
        editSourceButton.alpha = hasTrack ? 1 : 0.4
        addAudioButton.setTitle(hasTrack ? "Replace Audio" : "Add Audio", for: .normal)

        guard let track else {
            sourceLabel.text = "Source: -"
            return
        }

        trimmerView.asset = timelineAsset
        let compositionRange = CMTimeRange(start: .zero, duration: compositionDuration)
        trimmerView.clipTimeRange = compositionRange
        trimmerView.applySelectionRange(track.timelineTimeRange, clipBounds: compositionRange)
        // #region agent log
        agentLog(
            hypothesisId: "H1",
            location: "AudioSectionVC.configure:applySelectionRange",
            message: "applied selection",
            data: [
                "timelineStart": track.timelineTimeRange.start.seconds,
                "timelineDuration": track.timelineTimeRange.duration.seconds,
                "clipStart": compositionRange.start.seconds,
                "clipDuration": compositionRange.duration.seconds
            ]
        )
        // #endregion
        sourceLabel.text = "Source: \(formatRange(track.sourceTimeRange))"
    }

    private func setupUI() {
        trimmerView.translatesAutoresizingMaskIntoConstraints = false
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        sourceLabel.font = .systemFont(ofSize: 14, weight: .medium)
        sourceLabel.textColor = .white
        sourceLabel.text = "Source: -"
        sourceLabel.isHidden = true

        configureActionButton(addAudioButton, title: "Add Audio")
        addAudioButton.addTarget(self, action: #selector(addAudioTapped), for: .touchUpInside)

        configureActionButton(editSourceButton, title: "Edit Source")
        editSourceButton.addTarget(self, action: #selector(editSourceTapped), for: .touchUpInside)
        editSourceButton.isEnabled = false
        editSourceButton.alpha = 0.4

        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.addArrangedSubview(addAudioButton)
        buttonStack.addArrangedSubview(editSourceButton)

        trimmerView.delegate = self
        trimmerView.handleColor = .white
        trimmerView.mainColor = .systemBlue
        trimmerView.maskColor = .black
        trimmerView.positionBarColor = .clear
        trimmerView.minDuration = 0.5
        trimmerView.alpha = 0.4
        trimmerView.isUserInteractionEnabled = false
        trimmerView.isHidden = true

        view.addSubview(trimmerView)
        view.addSubview(sourceLabel)
        view.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            trimmerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            trimmerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            trimmerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            trimmerView.heightAnchor.constraint(equalToConstant: trimmerHeight),

            sourceLabel.topAnchor.constraint(equalTo: trimmerView.bottomAnchor, constant: 12),
            sourceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            sourceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            buttonStack.heightAnchor.constraint(equalToConstant: 40),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            buttonStack.topAnchor.constraint(greaterThanOrEqualTo: sourceLabel.bottomAnchor, constant: 12)
        ])
    }

    private func configureActionButton(_ button: UIButton, title: String) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.tintColor = .white
        button.layer.cornerRadius = 8
    }

    @objc private func addAudioTapped() {
        requestAddAudio?()
    }

    @objc private func editSourceTapped() {
        guard currentTrack != nil else { return }
        requestEditSource?()
    }

    private func formatRange(_ range: CMTimeRange) -> String {
        String(format: "%.2fs - %.2fs", range.start.seconds, range.end.seconds)
    }

    func recreateThumbnailsFor(asset: AVAsset, videoComposition: AVVideoComposition? = nil) async {
        // #region agent log
        agentLog(
            hypothesisId: "H2",
            location: "AudioSectionVC.recreateThumbnailsFor:before",
            message: "about to recreate thumbnails",
            data: [
                "assetDuration": asset.duration.seconds,
                "videoCompositionNil": videoComposition == nil
            ]
        )
        // #endregion
        await trimmerView.recreateThunmbnailsFor(
            asset: asset,
            videoComposition: videoComposition,
            trimmerHeight: trimmerHeight
        )
        if let track = currentTrack {
            let compositionRange = CMTimeRange(start: .zero, duration: compositionDuration)
            trimmerView.clipTimeRange = compositionRange
            trimmerView.applySelectionRange(track.timelineTimeRange, clipBounds: compositionRange)
            // #region agent log
            agentLog(
                hypothesisId: "H5",
                location: "AudioSectionVC.recreateThumbnailsFor:reapplySelection",
                message: "reapplied timeline selection after thumbnail regeneration",
                data: [
                    "timelineStart": track.timelineTimeRange.start.seconds,
                    "timelineDuration": track.timelineTimeRange.duration.seconds,
                    "compositionDuration": compositionDuration.seconds
                ]
            )
            // #endregion
        }
        // #region agent log
        agentLog(
            hypothesisId: "H2",
            location: "AudioSectionVC.recreateThumbnailsFor:after",
            message: "finished recreate thumbnails",
            data: [
                "startTimeAfter": trimmerView.startTime?.seconds ?? -1,
                "endTimeAfter": trimmerView.endTime?.seconds ?? -1
            ]
        )
        // #endregion
    }
}

extension AudioSectionVC: TrimmerViewDelegate {
    func didChangePositionBar(_ playerTime: CMTime) {}

    func positionBarStoppedMoving(_ playerTime: CMTime) {
        guard !isConfiguring,
              let start = trimmerView.startTime,
              let end = trimmerView.endTime else { return }
        let range = CMTimeRange(start: start, end: end)
        // #region agent log
        agentLog(
            hypothesisId: "H3",
            location: "AudioSectionVC.positionBarStoppedMoving",
            message: "user set timeline handles",
            data: [
                "start": start.seconds,
                "end": end.seconds,
                "duration": range.duration.seconds,
                "playerTime": playerTime.seconds
            ]
        )
        // #endregion
        timelineRangeDidChange?(range)
    }
}
