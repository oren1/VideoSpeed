import UIKit
import AVFoundation

typealias SplitTimeClosure = (CMTime) -> Void

class SplitSectionVC: SectionViewController {

    weak var delegate: TrimmerViewSpidDelegate!

    @IBOutlet weak var splitTimelineView: SplitTimelineView!
    @IBOutlet weak var splitButton: UIButton!
    @IBOutlet weak var hintLabel: UILabel!

    var splitConfirmed: SplitTimeClosure?

    private var playerItem: AVPlayerItem?
    private var isSplitInProgress = false

    func reloadTimelineFromOutside() async {
        await reloadTimeline()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.clipsToBounds = false
        splitTimelineView.splitDelegate = self
        splitButton.layer.cornerRadius = 8

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoSelectionChanged),
            name: Notification.Name.VideoSelectionChanged,
            object: nil
        )

        Task {
            await reloadTimeline()
        }
    }

    @objc private func videoSelectionChanged() {
        Task {
            await reloadTimeline()
        }
    }

    @IBAction func splitButtonTapped(_ sender: UIButton) {
        guard !isSplitInProgress,
              splitTimelineView.canSplit,
              let splitTime = splitTimelineView.currentSplitTime else {
            return
        }

        isSplitInProgress = true
        splitButton.isEnabled = false
        splitConfirmed?(splitTime)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            isSplitInProgress = false
            updateSplitButtonState()
        }
    }

    @MainActor
    private func reloadTimeline() async {
        guard let spidAsset = UserDataManager.main.currentSpidAsset else { return }

        let clipAsset = await spidAsset.getAsset()
        let timeRange = await spidAsset.timeRange
        playerItem = AVPlayerItem(asset: clipAsset)

        splitTimelineView.configure(asset: clipAsset, trimTimeRange: timeRange)
        splitTimelineView.generateClipThumbnails { _ in
            Task { @MainActor in
                self.updateSplitButtonState()
            }
        }

        updateSplitButtonState()
    }

    private func updateSplitButtonState() {
        let canSplit = splitTimelineView.canSplit
        splitButton.isEnabled = canSplit && !isSplitInProgress
        splitButton.alpha = splitButton.isEnabled ? 1 : 0.4
        hintLabel.text = canSplit
            ? "Drag to choose split point"
            : "Clip must be at least 2 seconds to split"
    }
}

extension SplitSectionVC: SplitTimelineViewDelegate {
    func splitTimeDidChange(_ time: CMTime) {
        Task { @MainActor in
            delegate?.spidPlayerController?.player?.pause()
            delegate?.spidPlayerController?.player?.replaceCurrentItem(with: playerItem)
            await delegate?.spidPlayerController?.player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        }
    }

    func splitTimeDidSettle(_ time: CMTime) {
        Task { @MainActor in
            delegate?.spidPlayerController?.player?.replaceCurrentItem(with: playerItem)
            await delegate?.spidPlayerController?.player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
            delegate?.spidPlayerController?.player?.play()
        }
    }
}
