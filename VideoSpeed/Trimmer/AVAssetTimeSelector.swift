
import UIKit
import AVFoundation

/// A generic class to display an asset into a scroll view with thumbnail images, and make the equivalence between a time in
// the asset and a position in the scroll view
public class AVAssetTimeSelector: UIView, UIScrollViewDelegate {

    let assetPreview = AssetVideoScrollView()

    /// The maximum duration allowed for the trimming. Change it before setting the asset, as the asset preview
    public var maxDuration: Double = 15 {
        didSet {
            assetPreview.maxDuration = maxDuration
        }
    }

    /// The asset to be displayed in the underlying scroll view. Setting a new asset will automatically refresh the thumbnails.
    public var asset: AVAsset? {
        didSet {
            assetDidChange(newAsset: asset)
        }
    }
    
    public var videoComposition: AVVideoComposition?

    /// When set, the timeline maps to this range on the asset instead of the full duration.
    public var clipTimeRange: CMTimeRange?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    func setupSubviews() {
        setupAssetPreview()
        constrainAssetPreview()
    }

    func recreateThunmbnailsFor(asset: AVAsset, videoComposition: AVVideoComposition? = nil, trimmerHeight: CGFloat) async {
        self.asset = asset
        self.videoComposition = videoComposition
        let _ = await preGenerateImagesWith(trimmerHeight: trimmerHeight)
        assetPreview.addThumbnails(for: asset)
    }
    
    public func preGenerateImagesWith(trimmerHeight: CGFloat) async -> [CGImage]?  {
        if let asset = asset {
            let trimmerAssetGenerator = TrimmerAssetsGenerator(asset: asset,
                                                               videoComposition: videoComposition,
                                                               trimmerWidth: UIScreen.main.bounds.width - 70,
                                                               trimmerHeight: trimmerHeight)
            assetPreview.images = await trimmerAssetGenerator.generateThumbnailImages()
            return assetPreview.images
        }
        return nil
    }
    
    public func regenerateThumbnails(frame: CGRect? = nil) {
        if let asset = asset {
            assetPreview.addThumbnails(for: asset)
//            assetPreview.regenerateThumbnails(for: asset, frame: frame)
        }
    }

    func replaceTo(thumbnailImages: [CGImage]) {
        if let asset = asset {
            assetPreview.images = thumbnailImages
            assetPreview.addThumbnails(for: asset)
        }
    }
    
    func generateThumbnails(completion: @escaping ([CGImage]) -> Void) {
        if let asset = asset {
            assetPreview.regenerateThumbnails(for: asset, completion: completion)
        }
    }

    func generateClipThumbnails(
        for timeRange: CMTimeRange,
        trimmerHeight: CGFloat,
        completion: @escaping ([CGImage]) -> Void
    ) {
        clipTimeRange = timeRange
        guard let asset else {
            completion([])
            return
        }

        let trimmerWidth = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width - 40
        let generator = TrimmerAssetsGenerator(
            asset: asset,
            videoComposition: videoComposition,
            trimmerWidth: trimmerWidth,
            trimmerHeight: trimmerHeight,
            timeRange: timeRange
        )

        Task {
            let images = await generator.generateThumbnailImages() ?? []
            await MainActor.run {
                self.replaceTo(thumbnailImages: images)
                self.assetPreview.contentOffset = .zero
                completion(images)
            }
        }
    }
    
    // MARK: - Asset Preview

    func setupAssetPreview() {
        self.translatesAutoresizingMaskIntoConstraints = false
        assetPreview.translatesAutoresizingMaskIntoConstraints = false
        assetPreview.delegate = self
        addSubview(assetPreview)
    }

    func constrainAssetPreview() {
        assetPreview.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        assetPreview.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        assetPreview.topAnchor.constraint(equalTo: topAnchor).isActive = true
        assetPreview.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    func assetDidChange(newAsset: AVAsset?) {
        if let asset = newAsset {
            assetPreview.addThumbnails(for: asset)
//            assetPreview.regenerateThumbnails(for: asset)
        }
    }

    // MARK: - Time & Position Equivalence

    var durationSize: CGFloat {
        return assetPreview.contentSize.width
    }

    func getTime(from position: CGFloat) -> CMTime? {
        if let clipTimeRange, clipTimeRange.duration.isValid, clipTimeRange.duration.seconds > 0 {
            let normalizedRatio = max(min(1, position / durationSize), 0)
            let offset = CMTimeMultiplyByFloat64(clipTimeRange.duration, multiplier: Double(normalizedRatio))
            return CMTimeAdd(clipTimeRange.start, offset)
        }

        guard let asset = asset else {
            return nil
        }
        let normalizedRatio = max(min(1, position / durationSize), 0)
        let positionTimeValue = Double(normalizedRatio) * Double(asset.duration.value)
        return CMTime(value: Int64(positionTimeValue), timescale: asset.duration.timescale)
    }

    func getPosition(from time: CMTime) -> CGFloat? {
        if let clipTimeRange, clipTimeRange.duration.isValid, clipTimeRange.duration.seconds > 0 {
            let elapsed = CMTimeSubtract(time, clipTimeRange.start)
            let ratio = elapsed.seconds / clipTimeRange.duration.seconds
            return CGFloat(max(0, min(1, ratio))) * durationSize
        }

        guard let asset = asset else {
            return nil
        }
        let timeRatio = CGFloat(time.value) * CGFloat(asset.duration.timescale) /
            (CGFloat(time.timescale) * CGFloat(asset.duration.value))
        return timeRatio * durationSize
    }
}
