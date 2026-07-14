//
//  AudioSourceTrimmerVC.swift
//  VideoSpeed
//

import UIKit
import AVFoundation
import CoreMedia

final class AudioSourceTrimmerVC: UIViewController {
    var onSourceRangeChanged: ((CMTimeRange) -> Void)?
    var onDone: VoidClousure?

    private let titleLabel = UILabel()
    private let rangeLabel = UILabel()
    private let trimmerView = AudioSourceTrimmerView()
    private let doneButton = UIButton(type: .system)

    private var track: BackgroundAudioTrackItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if let track {
            apply(track: track)
        }
    }

    func configure(track: BackgroundAudioTrackItem) {
        self.track = track
        guard isViewLoaded else { return }
        apply(track: track)
    }

    private func apply(track: BackgroundAudioTrackItem) {
        titleLabel.text = track.displayName
        rangeLabel.text = formatRange(track.sourceTimeRange)
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
            self.rangeLabel.text = self.formatRange(range)
            self.onSourceRangeChanged?(range)
        }

        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        doneButton.backgroundColor = .systemBlue
        doneButton.tintColor = .white
        doneButton.layer.cornerRadius = 10
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        rangeLabel.translatesAutoresizingMaskIntoConstraints = false
        trimmerView.translatesAutoresizingMaskIntoConstraints = false
        doneButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        view.addSubview(rangeLabel)
        view.addSubview(trimmerView)
        view.addSubview(doneButton)

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

            doneButton.topAnchor.constraint(equalTo: trimmerView.bottomAnchor, constant: 24),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 44),
            doneButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    @objc private func doneTapped() {
        onDone?()
    }

    private func formatRange(_ range: CMTimeRange) -> String {
        String(format: "%.2fs - %.2fs", range.start.seconds, range.end.seconds)
    }
}
