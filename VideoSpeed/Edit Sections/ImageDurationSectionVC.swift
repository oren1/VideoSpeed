//
//  ImageDurationSectionVC.swift
//  VideoSpeed
//

import UIKit

typealias DurationClosure = (Double) -> Void

class ImageDurationSectionVC: SectionViewController {

    private let titleLabel = UILabel()
    private let durationLabel = UILabel()
    private let slider = UISlider()
    private let minLabel = UILabel()
    private let maxLabel = UILabel()

    var durationDidChange: DurationClosure?
    var durationDidCommit: DurationClosure?

    private var durationSeconds: Double = ImageToVideoGenerator.defaultDurationSeconds {
        didSet { durationLabel.text = formatDuration(durationSeconds) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoSelectionChanged),
            name: Notification.Name.VideoSelectionChanged,
            object: nil
        )
        applyDuration(durationSeconds, notify: false)
    }

    private func setupViews() {
        titleLabel.text = "Duration"
        titleLabel.font = .systemFont(ofSize: 25)
        titleLabel.textColor = .white

        durationLabel.font = .systemFont(ofSize: 17)
        durationLabel.textColor = .white
        durationLabel.textAlignment = .center
        durationLabel.text = formatDuration(durationSeconds)

        minLabel.text = "3s"
        minLabel.font = .systemFont(ofSize: 17)
        minLabel.textColor = .white

        maxLabel.text = "60s"
        maxLabel.font = .systemFont(ofSize: 17)
        maxLabel.textColor = .white

        slider.minimumValue = Float(ImageToVideoGenerator.minDurationSeconds)
        slider.maximumValue = Float(ImageToVideoGenerator.maxDurationSeconds)
        slider.value = Float(ImageToVideoGenerator.defaultDurationSeconds)
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderReleased), for: [.touchUpInside, .touchUpOutside])

        [titleLabel, durationLabel, minLabel, maxLabel, slider].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            durationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            durationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            minLabel.centerYAnchor.constraint(equalTo: durationLabel.centerYAnchor),
            minLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),

            maxLabel.centerYAnchor.constraint(equalTo: durationLabel.centerYAnchor),
            maxLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            slider.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: 8),
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            slider.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24)
        ])
    }

    @objc private func sliderChanged() {
        durationSeconds = Double(slider.value.rounded())
        durationDidChange?(durationSeconds)
    }

    @objc private func sliderReleased() {
        durationSeconds = Double(slider.value.rounded())
        durationDidCommit?(durationSeconds)
    }

    private func applyDuration(_ duration: Double, notify: Bool) {
        durationSeconds = duration
        slider.value = Float(duration)
        if notify {
            durationDidCommit?(durationSeconds)
        }
    }

    @objc private func videoSelectionChanged() {
        Task { @MainActor in
            guard let spidAsset = UserDataManager.main.currentSpidAsset else { return }
            let seconds = await spidAsset.timeRange.duration.seconds
            applyDuration(seconds, notify: false)
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        if seconds.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(seconds))s"
        }
        return String(format: "%.1fs", seconds)
    }
}
