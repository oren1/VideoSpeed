//
//  AudioSectionVC.swift
//  VideoSpeed
//

import UIKit
import AVFoundation

final class AudioSectionVC: SectionViewController {
    var requestAddAudio: VoidClousure?
    var timelineRangeDidChange: ((CMTimeRange) -> Void)?

    private let addAudioButton = UIButton(type: .system)
    private let sourceLabel = UILabel()
    private let timelineLabel = UILabel()
    private let trimmerView = TrimmerView()
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
        sourceLabel.isHidden = !hasTrack
        timelineLabel.isHidden = !hasTrack
        trimmerView.isHidden = !hasTrack
        trimmerView.isUserInteractionEnabled = hasTrack
        trimmerView.alpha = hasTrack ? 1 : 0.4
        addAudioButton.isHidden = hasTrack

        guard let track else {
            sourceLabel.text = "Source: -"
            timelineLabel.text = "Timeline: -"
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
        timelineLabel.text = "Timeline: \(formatRange(track.timelineTimeRange))"
    }

    private func setupUI() {
        addAudioButton.translatesAutoresizingMaskIntoConstraints = false
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        timelineLabel.translatesAutoresizingMaskIntoConstraints = false
        trimmerView.translatesAutoresizingMaskIntoConstraints = false

        addAudioButton.setTitle("Add Audio", for: .normal)
        addAudioButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        addAudioButton.backgroundColor = .systemBlue
        addAudioButton.tintColor = .white
        addAudioButton.layer.cornerRadius = 8
        addAudioButton.addTarget(self, action: #selector(addAudioTapped), for: .touchUpInside)

        sourceLabel.font = .systemFont(ofSize: 14, weight: .medium)
        sourceLabel.textColor = .white
        sourceLabel.text = "Source: -"

        timelineLabel.font = .systemFont(ofSize: 14, weight: .medium)
        timelineLabel.textColor = .white
        timelineLabel.text = "Timeline: -"

        trimmerView.delegate = self
        trimmerView.handleColor = .white
        trimmerView.mainColor = .systemBlue
        trimmerView.maskColor = .black
        trimmerView.positionBarColor = .clear
        trimmerView.minDuration = 0.5
        trimmerView.alpha = 0.4
        trimmerView.isUserInteractionEnabled = false

        view.addSubview(addAudioButton)
        view.addSubview(sourceLabel)
        view.addSubview(timelineLabel)
        view.addSubview(trimmerView)

        NSLayoutConstraint.activate([
            addAudioButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            addAudioButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            addAudioButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            addAudioButton.heightAnchor.constraint(equalToConstant: 40),

            sourceLabel.topAnchor.constraint(equalTo: addAudioButton.bottomAnchor, constant: 12),
            sourceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            sourceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            timelineLabel.topAnchor.constraint(equalTo: sourceLabel.bottomAnchor, constant: 8),
            timelineLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            timelineLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            trimmerView.topAnchor.constraint(equalTo: timelineLabel.bottomAnchor, constant: 12),
            trimmerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            trimmerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            trimmerView.heightAnchor.constraint(equalToConstant: trimmerHeight),
            trimmerView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -12)
        ])
    }

    @objc private func addAudioTapped() {
        requestAddAudio?()
    }

    private func formatRange(_ range: CMTimeRange) -> String {
        let start = range.start.seconds
        let end = range.end.seconds
        return String(format: "%.2fs - %.2fs", start, end)
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
        timelineLabel.text = "Timeline: \(formatRange(range))"
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
