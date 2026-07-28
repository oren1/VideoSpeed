//
//  AudioSourceTrimmerVC.swift
//  VideoSpeed
//

import UIKit
import AVFoundation
import CoreMedia

final class AudioSourceTrimmerVC: UIViewController {
    var onSourceRangeChanged: ((CMTimeRange) -> Void)?
    var onVolumeChanged: ((Float) -> Void)?
    var onDone: VoidClousure?

    private let titleLabel = UILabel()
    private let rangeLabel = UILabel()
    private let trimmerView = AudioSourceTrimmerView()
    private let volumeTitleLabel = UILabel()
    private let volumeValueLabel = UILabel()
    private let volumeSlider = UISlider()
    private let doneButton = UIButton(type: .system)

    private var track: BackgroundAudioTrackItem?
    private var currentRange: CMTimeRange = .zero
    private var currentVolume: Float = 1.0

    private var previewPlayer: AVPlayer?
    private var timeObserver: Any?
    private var isPreviewActive = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if let track {
            apply(track: track)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startPreviewPlayback()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPreviewPlayback()
    }

    func configure(track: BackgroundAudioTrackItem) {
        self.track = track
        guard isViewLoaded else { return }
        apply(track: track)
        if isPreviewActive {
            restartPreviewFromRangeStart()
        }
    }

    private func apply(track: BackgroundAudioTrackItem) {
        titleLabel.text = track.displayName
        currentRange = track.sourceTimeRange
        currentVolume = track.volume
        rangeLabel.text = formatRange(currentRange)
        volumeSlider.value = track.volume
        updateVolumeLabel(track.volume)
        previewPlayer?.volume = track.volume
        trimmerView.configure(
            fileURL: track.fileURL,
            fullDuration: track.fullSourceRange.duration.seconds,
            selectedRange: track.sourceTimeRange
        )
    }

    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.1, alpha: 1)

        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1

        rangeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        rangeLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        rangeLabel.textAlignment = .center

        trimmerView.onSourceRangeChanged = { [weak self] range in
            guard let self else { return }
            self.currentRange = range
            self.rangeLabel.text = self.formatRange(range)
            self.onSourceRangeChanged?(range)
            if self.isPreviewActive {
                self.restartPreviewFromRangeStart()
            }
        }

        volumeTitleLabel.text = "Volume"
        volumeTitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        volumeTitleLabel.textColor = .white

        volumeValueLabel.font = .systemFont(ofSize: 14, weight: .medium)
        volumeValueLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        volumeValueLabel.textAlignment = .right
        updateVolumeLabel(currentVolume)

        volumeSlider.minimumValue = 0
        volumeSlider.maximumValue = 1
        volumeSlider.value = currentVolume
        volumeSlider.addTarget(self, action: #selector(volumeSliderChanged), for: .valueChanged)
        volumeSlider.addTarget(self, action: #selector(volumeSliderReleased), for: [.touchUpInside, .touchUpOutside])

        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        doneButton.backgroundColor = .systemBlue
        doneButton.tintColor = .white
        doneButton.layer.cornerRadius = 10
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)

        [titleLabel, rangeLabel, trimmerView, volumeTitleLabel, volumeValueLabel, volumeSlider, doneButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            rangeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            rangeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            rangeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            trimmerView.topAnchor.constraint(equalTo: rangeLabel.bottomAnchor, constant: 20),
            trimmerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            trimmerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            trimmerView.heightAnchor.constraint(equalToConstant: 96),

            volumeTitleLabel.topAnchor.constraint(equalTo: trimmerView.bottomAnchor, constant: 20),
            volumeTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            volumeValueLabel.centerYAnchor.constraint(equalTo: volumeTitleLabel.centerYAnchor),
            volumeValueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            volumeValueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: volumeTitleLabel.trailingAnchor, constant: 8),

            volumeSlider.topAnchor.constraint(equalTo: volumeTitleLabel.bottomAnchor, constant: 8),
            volumeSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            volumeSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            doneButton.topAnchor.constraint(equalTo: volumeSlider.bottomAnchor, constant: 20),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 44),
            doneButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    @objc private func volumeSliderChanged() {
        currentVolume = volumeSlider.value
        updateVolumeLabel(currentVolume)
        previewPlayer?.volume = currentVolume
    }

    @objc private func volumeSliderReleased() {
        currentVolume = volumeSlider.value
        updateVolumeLabel(currentVolume)
        previewPlayer?.volume = currentVolume
        onVolumeChanged?(currentVolume)
    }

    private func updateVolumeLabel(_ volume: Float) {
        volumeValueLabel.text = "\(Int((volume * 100).rounded()))%"
    }

    // MARK: - Preview playback

    private func startPreviewPlayback() {
        guard let track else { return }
        stopPreviewPlayback()

        let player = AVPlayer(url: track.fileURL)
        player.volume = currentVolume
        previewPlayer = player
        isPreviewActive = true

        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.handlePreviewTime(time)
        }

        restartPreviewFromRangeStart()
    }

    private func stopPreviewPlayback() {
        isPreviewActive = false
        if let timeObserver, let previewPlayer {
            previewPlayer.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        previewPlayer?.pause()
        previewPlayer?.replaceCurrentItem(with: nil)
        previewPlayer = nil
    }

    private func restartPreviewFromRangeStart() {
        guard isPreviewActive, let previewPlayer, currentRange.duration.seconds > 0 else { return }
        let start = currentRange.start
        previewPlayer.seek(to: start, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            guard finished, let self, self.isPreviewActive else { return }
            self.previewPlayer?.play()
        }
    }

    private func handlePreviewTime(_ time: CMTime) {
        guard isPreviewActive, currentRange.duration.seconds > 0 else { return }
        if time >= currentRange.end {
            restartPreviewFromRangeStart()
        }
    }

    @objc private func doneTapped() {
        stopPreviewPlayback()
        onDone?()
    }

    private func formatRange(_ range: CMTimeRange) -> String {
        String(format: "%.2fs - %.2fs", range.start.seconds, range.end.seconds)
    }
}
