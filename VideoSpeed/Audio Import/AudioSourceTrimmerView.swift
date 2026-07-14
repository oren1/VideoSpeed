//
//  AudioSourceTrimmerView.swift
//  VideoSpeed
//

import UIKit
import AVFoundation
import CoreMedia

final class AudioSourceTrimmerView: UIView {
    var onSourceRangeChanged: ((CMTimeRange) -> Void)?

    private let trackContainer = UIView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let waveformView = WaveformRenderView()
    private let leftHandleLine = UIView()
    private let rightHandleLine = UIView()
    private let leftHandleTimeLabel = UILabel()
    private let leftDimOverlay = UIView()
    private let rightDimOverlay = UIView()
    private var contentWidthConstraint: NSLayoutConstraint?

    private let handleLineWidth: CGFloat = 2
    private let sidePeekWidth: CGFloat = 20
    private let timeLabelHeight: CGFloat = 18
    private let timeLabelSpacing: CGFloat = 6
    private var pixelsPerSecond: CGFloat = 48
    private var sourceDuration: TimeInterval = 0
    /// Kept in sync with timelineTimeRange / sourceTimeRange duration.
    private var selectionDuration: TimeInterval = 0
    private var isConfiguring = false
    private var waveformLoadToken = UUID()
    private var loadedFileURL: URL?

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
        updateContentWidth()
        updateScrollInsets()
        updateDimOverlays()
    }

    func configure(fileURL: URL, fullDuration: TimeInterval, selectedRange: CMTimeRange) {
        isConfiguring = true
        defer { isConfiguring = false }

        sourceDuration = max(fullDuration, 0.1)
        selectionDuration = max(selectedRange.duration.seconds, 0.1)
        selectionDuration = min(selectionDuration, sourceDuration)
        updateScaleFromSelectionDuration()
        updateContentWidth()
        updateScrollInsets()
        layoutIfNeeded()
        applySelectedRange(selectedRange)
        updateDimOverlays()
        updateLeftHandleTimeLabel()
        loadWaveformIfNeeded(fileURL: fileURL)
    }

    private var selectionFrameWidth: CGFloat {
        max(1, trackContainer.bounds.width - (2 * sidePeekWidth) - (2 * handleLineWidth))
    }

    private var selectionFrameStartX: CGFloat {
        sidePeekWidth + handleLineWidth
    }

    private var selectionFrameEndX: CGFloat {
        trackContainer.bounds.width - sidePeekWidth - handleLineWidth
    }

    private func updateScaleFromSelectionDuration() {
        guard selectionDuration > 0, trackContainer.bounds.width > 0 else { return }
        pixelsPerSecond = selectionFrameWidth / CGFloat(selectionDuration)
    }

    private func setupUI() {
        backgroundColor = .clear
        clipsToBounds = false

        trackContainer.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        trackContainer.layer.cornerRadius = 8
        trackContainer.clipsToBounds = true

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        scrollView.clipsToBounds = true
        scrollView.contentInsetAdjustmentBehavior = .never

        waveformView.backgroundColor = .clear
        waveformView.isOpaque = false
        waveformView.isUserInteractionEnabled = false

        leftHandleLine.backgroundColor = .white
        rightHandleLine.backgroundColor = .white

        leftHandleTimeLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        leftHandleTimeLabel.textColor = .white
        leftHandleTimeLabel.textAlignment = .center
        leftHandleTimeLabel.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        leftHandleTimeLabel.layer.cornerRadius = 4
        leftHandleTimeLabel.clipsToBounds = true
        leftHandleTimeLabel.text = "0.0s"

        leftDimOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        leftDimOverlay.isUserInteractionEnabled = false
        rightDimOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        rightDimOverlay.isUserInteractionEnabled = false

        trackContainer.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        leftHandleLine.translatesAutoresizingMaskIntoConstraints = false
        rightHandleLine.translatesAutoresizingMaskIntoConstraints = false
        leftHandleTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        leftDimOverlay.translatesAutoresizingMaskIntoConstraints = false
        rightDimOverlay.translatesAutoresizingMaskIntoConstraints = false

        addSubview(leftHandleTimeLabel)
        addSubview(trackContainer)
        trackContainer.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(waveformView)
        trackContainer.addSubview(leftDimOverlay)
        trackContainer.addSubview(rightDimOverlay)
        trackContainer.addSubview(leftHandleLine)
        trackContainer.addSubview(rightHandleLine)

        contentWidthConstraint = contentView.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            leftHandleTimeLabel.topAnchor.constraint(equalTo: topAnchor),
            leftHandleTimeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
            leftHandleTimeLabel.heightAnchor.constraint(equalToConstant: timeLabelHeight),

            trackContainer.topAnchor.constraint(equalTo: leftHandleTimeLabel.bottomAnchor, constant: timeLabelSpacing),
            trackContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            trackContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            trackContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Align the label with the left handle after the track container lays out.
            leftHandleTimeLabel.centerXAnchor.constraint(equalTo: trackContainer.leadingAnchor, constant: sidePeekWidth + handleLineWidth / 2),

            scrollView.leadingAnchor.constraint(equalTo: trackContainer.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trackContainer.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: trackContainer.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: trackContainer.bottomAnchor),

            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
            contentWidthConstraint!,

            waveformView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            waveformView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            waveformView.topAnchor.constraint(equalTo: contentView.topAnchor),
            waveformView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            leftHandleLine.leadingAnchor.constraint(equalTo: trackContainer.leadingAnchor, constant: sidePeekWidth),
            leftHandleLine.topAnchor.constraint(equalTo: trackContainer.topAnchor),
            leftHandleLine.bottomAnchor.constraint(equalTo: trackContainer.bottomAnchor),
            leftHandleLine.widthAnchor.constraint(equalToConstant: handleLineWidth),

            rightHandleLine.trailingAnchor.constraint(equalTo: trackContainer.trailingAnchor, constant: -sidePeekWidth),
            rightHandleLine.topAnchor.constraint(equalTo: trackContainer.topAnchor),
            rightHandleLine.bottomAnchor.constraint(equalTo: trackContainer.bottomAnchor),
            rightHandleLine.widthAnchor.constraint(equalToConstant: handleLineWidth),

            leftDimOverlay.leadingAnchor.constraint(equalTo: trackContainer.leadingAnchor),
            leftDimOverlay.topAnchor.constraint(equalTo: trackContainer.topAnchor),
            leftDimOverlay.bottomAnchor.constraint(equalTo: trackContainer.bottomAnchor),
            leftDimOverlay.trailingAnchor.constraint(equalTo: leftHandleLine.leadingAnchor),

            rightDimOverlay.trailingAnchor.constraint(equalTo: trackContainer.trailingAnchor),
            rightDimOverlay.topAnchor.constraint(equalTo: trackContainer.topAnchor),
            rightDimOverlay.bottomAnchor.constraint(equalTo: trackContainer.bottomAnchor),
            rightDimOverlay.leadingAnchor.constraint(equalTo: rightHandleLine.trailingAnchor)
        ])
    }

    private func updateContentWidth() {
        let contentWidth = max(CGFloat(sourceDuration) * pixelsPerSecond, 1)
        contentWidthConstraint?.constant = contentWidth
        waveformView.setNeedsDisplay()
    }

    private func updateScrollInsets() {
        guard trackContainer.bounds.width > 0 else { return }
        let leadingInset = selectionFrameStartX
        let trailingInset = trackContainer.bounds.width - selectionFrameEndX
        scrollView.contentInset = UIEdgeInsets(top: 0, left: leadingInset, bottom: 0, right: trailingInset)
    }

    private func loadWaveformIfNeeded(fileURL: URL) {
        if loadedFileURL == fileURL, !waveformView.amplitudes.isEmpty {
            return
        }
        loadedFileURL = fileURL
        let token = UUID()
        waveformLoadToken = token

        if waveformView.amplitudes.isEmpty {
            waveformView.amplitudes = Array(repeating: 0.12, count: 64)
        }

        Task {
            let amplitudes = await AudioWaveformSampler.sampleAmplitudes(from: fileURL) { partial in
                Task { @MainActor in
                    guard self.waveformLoadToken == token else { return }
                    self.waveformView.amplitudes = partial
                }
            }
            await MainActor.run {
                guard self.waveformLoadToken == token else { return }
                self.waveformView.amplitudes = amplitudes
            }
        }
    }

    private func updateDimOverlays() {}

    private func applySelectedRange(_ range: CMTimeRange) {
        updateScrollInsets()
        layoutIfNeeded()

        let leadingInset = selectionFrameStartX
        let trailingInset = trackContainer.bounds.width - selectionFrameEndX
        let contentWidth = scrollView.contentSize.width
        let boundsWidth = scrollView.bounds.width

        // offset = start*pps - leadingInset; start=0 → offset = -leadingInset
        let targetOffset = CGFloat(range.start.seconds) * pixelsPerSecond - leadingInset
        let minOffset = -leadingInset
        let maxOffset = max(minOffset, contentWidth - boundsWidth + trailingInset)
        let offsetX = min(max(targetOffset, minOffset), maxOffset)
        scrollView.contentOffset = CGPoint(x: offsetX, y: 0)
        updateLeftHandleTimeLabel()
    }

    private func currentSelectedRange() -> CMTimeRange {
        // Time under the left handle.
        let startSeconds = max(0, Double((scrollView.contentOffset.x + selectionFrameStartX) / pixelsPerSecond))
        let maxStart = max(0, sourceDuration - selectionDuration)
        let clampedStart = min(startSeconds, maxStart)
        let timescale: CMTimeScale = 600
        return CMTimeRange(
            start: CMTime(seconds: clampedStart, preferredTimescale: timescale),
            duration: CMTime(seconds: selectionDuration, preferredTimescale: timescale)
        )
    }

    private func updateLeftHandleTimeLabel() {
        let startSeconds = currentSelectedRange().start.seconds
        leftHandleTimeLabel.text = String(format: "%.1fs", startSeconds)
    }

    private func reportRangeIfNeeded() {
        guard !isConfiguring else { return }
        onSourceRangeChanged?(currentSelectedRange())
    }
}

extension AudioSourceTrimmerView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateDimOverlays()
        updateLeftHandleTimeLabel()
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

final class WaveformRenderView: UIView {
    var amplitudes: [CGFloat] = [] {
        didSet { setNeedsDisplay() }
    }

    var barColor: UIColor = .systemBlue

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), !amplitudes.isEmpty, rect.width > 0 else { return }

        let count = amplitudes.count
        let barSlotWidth = rect.width / CGFloat(count)
        let barWidth = max(1, barSlotWidth * 0.7)
        let midY = rect.midY
        let maxBarHeight = max(2, rect.height - 4)

        context.setFillColor(barColor.cgColor)

        for (index, amplitude) in amplitudes.enumerated() {
            let normalized = max(0.08, min(1, amplitude))
            let barHeight = maxBarHeight * normalized
            let x = CGFloat(index) * barSlotWidth + (barSlotWidth - barWidth) / 2
            let y = midY - barHeight / 2
            let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
            let path = UIBezierPath(roundedRect: barRect, cornerRadius: barWidth / 2)
            context.addPath(path.cgPath)
        }
        context.fillPath()
    }
}
