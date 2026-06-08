import AVFoundation
import UIKit

protocol SplitTimelineViewDelegate: AnyObject {
    func splitTimeDidChange(_ time: CMTime)
    func splitTimeDidSettle(_ time: CMTime)
}

class SplitTimelineView: AVAssetTimeSelector {

    weak var splitDelegate: SplitTimelineViewDelegate?

    var trimTimeRange: CMTimeRange = .zero {
        didSet {
            layoutIfNeeded()
            updateMarkerPosition(for: currentSplitTime ?? defaultSplitTime(), notifyDelegate: false)
        }
    }

    var minSegmentDuration: Double = 1.0

    private(set) var currentSplitTime: CMTime?

    private let splitMarkerContainer = UIView()
    private let splitMarker = UIView()
    private var markerLeadingConstraint: NSLayoutConstraint?
    private let markerVisualWidth: CGFloat = 4
    private let markerTouchWidth: CGFloat = 44
    private let trimmerHeight: CGFloat = 60

    override func setupSubviews() {
        super.setupSubviews()
        setupSplitMarker()
        setupMarkerGesture()
        assetPreview.contentOffset = .zero
    }

    func configure(asset: AVAsset, trimTimeRange: CMTimeRange) {
        self.trimTimeRange = trimTimeRange
        self.asset = asset
        assetPreview.contentOffset = .zero
        layoutIfNeeded()

        let initialTime = defaultSplitTime()
        updateMarkerPosition(for: initialTime, notifyDelegate: false)
    }

    func generateClipThumbnails(completion: @escaping ([CGImage]) -> Void) {
        guard let asset else {
            completion([])
            return
        }

        let trimmerWidth = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width - 40
        let generator = TrimmerAssetsGenerator(
            asset: asset,
            trimmerWidth: trimmerWidth,
            trimmerHeight: trimmerHeight,
            timeRange: trimTimeRange
        )

        Task {
            let images = await generator.generateThumbnailImages() ?? []
            await MainActor.run {
                self.replaceTo(thumbnailImages: images)
                self.assetPreview.contentOffset = .zero
                if let time = self.currentSplitTime {
                    self.updateMarkerPosition(for: time, notifyDelegate: false)
                }
                completion(images)
            }
        }
    }

    func setSplitTime(_ time: CMTime) {
        updateMarkerPosition(for: clampedSplitTime(time), notifyDelegate: false)
    }

    var canSplit: Bool {
        trimTimeRange.duration.seconds > (minSegmentDuration * 2)
    }

    override func assetDidChange(newAsset: AVAsset?) {
        // Thumbnails are generated explicitly for the clip timeRange.
    }

    override func getTime(from position: CGFloat) -> CMTime? {
        guard trimTimeRange.duration.isValid, trimTimeRange.duration.seconds > 0 else {
            return trimTimeRange.start
        }
        let normalizedRatio = max(min(1, position / durationSize), 0)
        let offset = CMTimeMultiplyByFloat64(trimTimeRange.duration, multiplier: Double(normalizedRatio))
        return CMTimeAdd(trimTimeRange.start, offset)
    }

    override func getPosition(from time: CMTime) -> CGFloat? {
        guard trimTimeRange.duration.isValid, trimTimeRange.duration.seconds > 0 else {
            return 0
        }
        let elapsed = CMTimeSubtract(time, trimTimeRange.start)
        let ratio = elapsed.seconds / trimTimeRange.duration.seconds
        return CGFloat(max(0, min(1, ratio))) * durationSize
    }

    private func setupSplitMarker() {
        splitMarkerContainer.translatesAutoresizingMaskIntoConstraints = false
        splitMarkerContainer.backgroundColor = .clear
        addSubview(splitMarkerContainer)

        splitMarker.translatesAutoresizingMaskIntoConstraints = false
        splitMarker.backgroundColor = .systemBlue
        splitMarker.layer.cornerRadius = markerVisualWidth / 2
        splitMarker.layer.masksToBounds = true
        splitMarkerContainer.addSubview(splitMarker)

        markerLeadingConstraint = splitMarkerContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0)
        NSLayoutConstraint.activate([
            markerLeadingConstraint!,
            splitMarkerContainer.topAnchor.constraint(equalTo: topAnchor),
            splitMarkerContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            splitMarkerContainer.widthAnchor.constraint(equalToConstant: markerTouchWidth),

            splitMarker.centerXAnchor.constraint(equalTo: splitMarkerContainer.centerXAnchor),
            splitMarker.topAnchor.constraint(equalTo: splitMarkerContainer.topAnchor),
            splitMarker.bottomAnchor.constraint(equalTo: splitMarkerContainer.bottomAnchor),
            splitMarker.widthAnchor.constraint(equalToConstant: markerVisualWidth)
        ])
    }

    private func setupMarkerGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleMarkerPan(_:)))
        splitMarkerContainer.addGestureRecognizer(pan)
        splitMarkerContainer.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTimelineTap(_:)))
        addGestureRecognizer(tap)
    }

    @objc private func handleMarkerPan(_ gesture: UIPanGestureRecognizer) {
        guard canSplit else { return }

        let location = gesture.location(in: self)
        let absoluteTime = absoluteTime(forViewX: location.x)
        updateMarkerPosition(for: absoluteTime, notifyDelegate: gesture.state == .changed)

        switch gesture.state {
        case .ended, .cancelled, .failed:
            if let time = currentSplitTime {
                splitDelegate?.splitTimeDidSettle(time)
            }
        default:
            break
        }
    }

    @objc private func handleTimelineTap(_ gesture: UITapGestureRecognizer) {
        guard canSplit else { return }

        let location = gesture.location(in: self)
        let absoluteTime = absoluteTime(forViewX: location.x)
        updateMarkerPosition(for: absoluteTime, notifyDelegate: false)
        if let time = currentSplitTime {
            splitDelegate?.splitTimeDidSettle(time)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bringSubviewToFront(splitMarkerContainer)
        if let time = currentSplitTime {
            updateMarkerPosition(for: time, notifyDelegate: false)
        }
    }

    private func updateMarkerPosition(for time: CMTime, notifyDelegate: Bool) {
        let clamped = clampedSplitTime(time)
        currentSplitTime = clamped

        guard let position = contentPosition(for: clamped) else { return }
        markerLeadingConstraint?.constant = position - (markerTouchWidth / 2)
        layoutIfNeeded()

        if notifyDelegate {
            splitDelegate?.splitTimeDidChange(clamped)
        }
    }

    private func defaultSplitTime() -> CMTime {
        guard trimTimeRange.duration.isValid, trimTimeRange.duration.seconds > 0 else {
            return trimTimeRange.start
        }
        let midpoint = CMTimeAdd(trimTimeRange.start, CMTimeMultiplyByFloat64(trimTimeRange.duration, multiplier: 0.5))
        return clampedSplitTime(midpoint)
    }

    private func clampedSplitTime(_ time: CMTime) -> CMTime {
        let minTime = CMTimeAdd(trimTimeRange.start, CMTime(seconds: minSegmentDuration, preferredTimescale: time.timescale))
        let maxTime = CMTimeSubtract(trimTimeRange.end, CMTime(seconds: minSegmentDuration, preferredTimescale: time.timescale))

        if CMTimeCompare(time, minTime) < 0 { return minTime }
        if CMTimeCompare(time, maxTime) > 0 { return maxTime }
        return time
    }

    private func contentPosition(for time: CMTime) -> CGFloat? {
        guard let contentPosition = getPosition(from: time) else { return nil }
        return contentPosition - assetPreview.contentOffset.x
    }

    private func absoluteTime(forViewX viewX: CGFloat) -> CMTime {
        let contentX = viewX + assetPreview.contentOffset.x
        return getTime(from: contentX) ?? trimTimeRange.start
    }
}
