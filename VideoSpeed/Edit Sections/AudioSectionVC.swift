//
//  AudioSectionVC.swift
//  VideoSpeed
//

import UIKit
import AVFoundation

final class AudioSectionVC: SectionViewController {
    var requestAddAudio: VoidClousure?
    var timelineRangeDidChange: ((CMTimeRange) -> Void)?
    var sourceTimeRangeDidChange: ((CMTimeRange) -> Void)?

    private let addAudioButton = UIButton(type: .system)
    private let sourceLabel = UILabel()
    private let timelineLabel = UILabel()
    private let trimmerView = TrimmerView()
    private let sourceTrimmerView = AudioSourceTrimmerView()
    private let trimmerHeight = 56.0
    private let sourceTrimmerHeight = 48.0
    private var addAudioButtonHeightConstraint: NSLayoutConstraint!

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
        sourceTrimmerView.isHidden = !hasTrack
        trimmerView.isUserInteractionEnabled = hasTrack
        sourceTrimmerView.isUserInteractionEnabled = hasTrack
        trimmerView.alpha = hasTrack ? 1 : 0.4
        sourceTrimmerView.alpha = hasTrack ? 1 : 0.4
        addAudioButton.isHidden = hasTrack
        addAudioButtonHeightConstraint.constant = hasTrack ? 0 : 40

        guard let track else {
            sourceLabel.text = "Source: -"
            timelineLabel.text = "Timeline: -"
            return
        }

        trimmerView.asset = timelineAsset
        let compositionRange = CMTimeRange(start: .zero, duration: compositionDuration)
        trimmerView.clipTimeRange = compositionRange
        trimmerView.applySelectionRange(track.timelineTimeRange, clipBounds: compositionRange)
        sourceTrimmerView.configure(
            fullDuration: track.fullSourceRange.duration.seconds,
            selectedRange: track.sourceTimeRange
        )
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
        sourceTrimmerView.translatesAutoresizingMaskIntoConstraints = false

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

        sourceTrimmerView.onSourceRangeChanged = { [weak self] range in
            guard let self, !self.isConfiguring else { return }
            self.sourceLabel.text = "Source: \(self.formatRange(range))"
            self.sourceTimeRangeDidChange?(range)
        }

        trimmerView.delegate = self
        trimmerView.handleColor = .white
        trimmerView.mainColor = .systemBlue
        trimmerView.maskColor = .black
        trimmerView.positionBarColor = .clear
        trimmerView.minDuration = 0.5
        trimmerView.alpha = 0.4
        trimmerView.isUserInteractionEnabled = false

        view.addSubview(addAudioButton)
        view.addSubview(timelineLabel)
        view.addSubview(trimmerView)
        view.addSubview(sourceLabel)
        view.addSubview(sourceTrimmerView)

        NSLayoutConstraint.activate([
            addAudioButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            addAudioButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            addAudioButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            timelineLabel.topAnchor.constraint(equalTo: addAudioButton.bottomAnchor, constant: 12),
            timelineLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            timelineLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            trimmerView.topAnchor.constraint(equalTo: timelineLabel.bottomAnchor, constant: 8),
            trimmerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            trimmerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            trimmerView.heightAnchor.constraint(equalToConstant: trimmerHeight),

            sourceLabel.topAnchor.constraint(equalTo: trimmerView.bottomAnchor, constant: 12),
            sourceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            sourceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            sourceTrimmerView.topAnchor.constraint(equalTo: sourceLabel.bottomAnchor, constant: 8),
            sourceTrimmerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            sourceTrimmerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            sourceTrimmerView.heightAnchor.constraint(equalToConstant: sourceTrimmerHeight),
            sourceTrimmerView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -12)
        ])
        addAudioButtonHeightConstraint = addAudioButton.heightAnchor.constraint(equalToConstant: 40)
        addAudioButtonHeightConstraint.isActive = true
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
            sourceTrimmerView.configure(
                fullDuration: track.fullSourceRange.duration.seconds,
                selectedRange: track.sourceTimeRange
            )
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

// MARK: - AudioSourceTrimmerView

final class AudioSourceTrimmerView: UIView {
    var onSourceRangeChanged: ((CMTimeRange) -> Void)?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let leftHandleLine = UIView()
    private let rightHandleLine = UIView()
    private let leftDimOverlay = UIView()
    private let rightDimOverlay = UIView()
    private var contentWidthConstraint: NSLayoutConstraint?

    private let handleLineWidth: CGFloat = 2
    private let sidePeekWidth: CGFloat = 20
    private var pixelsPerSecond: CGFloat = 48
    private var sourceDuration: TimeInterval = 0
    /// Kept in sync with timelineTimeRange / sourceTimeRange duration.
    private var selectionDuration: TimeInterval = 0
    private var isConfiguring = false
    private var lastBuiltContentKey: String = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard sourceDuration > 0, selectionDuration > 0 else { return }
        updateScaleFromSelectionDuration()
        rebuildTimelineContentIfNeeded()
        updateDimOverlays()
    }

    func configure(fullDuration: TimeInterval, selectedRange: CMTimeRange) {
        isConfiguring = true
        defer { isConfiguring = false }

        sourceDuration = max(fullDuration, 0.1)
        selectionDuration = max(selectedRange.duration.seconds, 0.1)
        selectionDuration = min(selectionDuration, sourceDuration)
        updateScaleFromSelectionDuration()
        rebuildTimelineContentIfNeeded()
        layoutIfNeeded()
        applySelectedRange(selectedRange)
        updateDimOverlays()
    }

    private var selectionFrameWidth: CGFloat {
        max(1, bounds.width - (2 * sidePeekWidth) - (2 * handleLineWidth))
    }

    private var selectionFrameStartX: CGFloat {
        sidePeekWidth + handleLineWidth
    }

    private var selectionFrameEndX: CGFloat {
        bounds.width - sidePeekWidth - handleLineWidth
    }

    private func updateScaleFromSelectionDuration() {
        guard selectionDuration > 0, bounds.width > 0 else { return }
        // Scale so the window between the handle lines represents selectionDuration.
        pixelsPerSecond = selectionFrameWidth / CGFloat(selectionDuration)
    }

    private func setupUI() {
        backgroundColor = UIColor.white.withAlphaComponent(0.08)
        layer.cornerRadius = 8
        clipsToBounds = true

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        scrollView.clipsToBounds = true

        leftHandleLine.backgroundColor = .white
        rightHandleLine.backgroundColor = .white

        leftDimOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        leftDimOverlay.isUserInteractionEnabled = false
        rightDimOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        rightDimOverlay.isUserInteractionEnabled = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        leftHandleLine.translatesAutoresizingMaskIntoConstraints = false
        rightHandleLine.translatesAutoresizingMaskIntoConstraints = false
        leftDimOverlay.translatesAutoresizingMaskIntoConstraints = false
        rightDimOverlay.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)
        scrollView.addSubview(contentView)
        addSubview(leftDimOverlay)
        addSubview(rightDimOverlay)
        addSubview(leftHandleLine)
        addSubview(rightHandleLine)

        contentWidthConstraint = contentView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            contentWidthConstraint!,

            leftHandleLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: sidePeekWidth),
            leftHandleLine.topAnchor.constraint(equalTo: topAnchor),
            leftHandleLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            leftHandleLine.widthAnchor.constraint(equalToConstant: handleLineWidth),

            rightHandleLine.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -sidePeekWidth),
            rightHandleLine.topAnchor.constraint(equalTo: topAnchor),
            rightHandleLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            rightHandleLine.widthAnchor.constraint(equalToConstant: handleLineWidth),

            leftDimOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftDimOverlay.topAnchor.constraint(equalTo: topAnchor),
            leftDimOverlay.bottomAnchor.constraint(equalTo: bottomAnchor),
            leftDimOverlay.trailingAnchor.constraint(equalTo: leftHandleLine.leadingAnchor),

            rightDimOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightDimOverlay.topAnchor.constraint(equalTo: topAnchor),
            rightDimOverlay.bottomAnchor.constraint(equalTo: bottomAnchor),
            rightDimOverlay.leadingAnchor.constraint(equalTo: rightHandleLine.trailingAnchor)
        ])
    }

    private func rebuildTimelineContentIfNeeded() {
        let contentWidth = CGFloat(sourceDuration) * pixelsPerSecond
        let resolvedWidth = max(contentWidth, selectionFrameWidth)
        contentWidthConstraint?.constant = resolvedWidth

        let contentKey = String(format: "%.3f-%.3f-%.1f", sourceDuration, selectionDuration, resolvedWidth)
        guard contentKey != lastBuiltContentKey else {
            updateContentHighlighting()
            return
        }
        lastBuiltContentKey = contentKey

        contentView.subviews.forEach { $0.removeFromSuperview() }

        let totalSeconds = Int(ceil(sourceDuration))
        for second in 0...totalSeconds {
            let x = CGFloat(second) * pixelsPerSecond

            let tick = UIView()
            tick.backgroundColor = UIColor.white.withAlphaComponent(0.35)
            tick.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(tick)

            let label = UILabel()
            label.text = "\(second)s"
            label.font = .systemFont(ofSize: 11, weight: .medium)
            label.textColor = .white
            label.tag = second
            label.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(label)

            NSLayoutConstraint.activate([
                tick.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: x),
                tick.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
                tick.widthAnchor.constraint(equalToConstant: 1),
                tick.heightAnchor.constraint(equalToConstant: 10),

                label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: x + 4),
                label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 6)
            ])
        }

        updateContentHighlighting()
    }

    private func updateDimOverlays() {
        updateContentHighlighting()
    }

    private func updateContentHighlighting() {
        let selection = currentSelectedRange()
        let startSecond = selection.start.seconds
        let endSecond = selection.end.seconds
        let frameStartX = selectionFrameStartX
        let frameEndX = selectionFrameEndX
        let offsetX = scrollView.contentOffset.x

        for subview in contentView.subviews {
            guard let label = subview as? UILabel, label.tag >= 0 else { continue }
            let second = Double(label.tag)
            let labelXInViewport = CGFloat(second) * pixelsPerSecond - offsetX + 4

            let isInTimeRange = second >= startSecond && second <= endSecond
            let isInFrame = labelXInViewport >= frameStartX && labelXInViewport <= frameEndX
            let isHighlighted = isInTimeRange && isInFrame

            label.textColor = isHighlighted ? .white : UIColor.white.withAlphaComponent(0.35)
            label.font = .systemFont(ofSize: 11, weight: isHighlighted ? .semibold : .medium)
        }
    }

    private func applySelectedRange(_ range: CMTimeRange) {
        let targetOffset = CGFloat(range.start.seconds) * pixelsPerSecond - selectionFrameStartX
        let maxOffset = max(0, scrollView.contentSize.width - scrollView.bounds.width)
        let offsetX = min(max(0, targetOffset), maxOffset)
        scrollView.contentOffset = CGPoint(x: offsetX, y: 0)
        updateDimOverlays()
    }

    private func currentSelectedRange() -> CMTimeRange {
        let startSeconds = max(0, Double((scrollView.contentOffset.x + selectionFrameStartX) / pixelsPerSecond))
        let maxStart = max(0, sourceDuration - selectionDuration)
        let clampedStart = min(startSeconds, maxStart)
        let timescale: CMTimeScale = 600
        return CMTimeRange(
            start: CMTime(seconds: clampedStart, preferredTimescale: timescale),
            duration: CMTime(seconds: selectionDuration, preferredTimescale: timescale)
        )
    }

    private func reportRangeIfNeeded() {
        guard !isConfiguring else { return }
        onSourceRangeChanged?(currentSelectedRange())
    }
}

extension AudioSourceTrimmerView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateDimOverlays()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        reportRangeIfNeeded()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            reportRangeIfNeeded()
        }
    }
}
