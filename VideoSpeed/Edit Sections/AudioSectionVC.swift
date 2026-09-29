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

    private var buttonStackLeadingConstraint: NSLayoutConstraint?
    private var buttonStackTrailingConstraint: NSLayoutConstraint?
    private var buttonStackCenterXConstraint: NSLayoutConstraint?
    private var addAudioButtonWidthConstraint: NSLayoutConstraint?

    private var currentTrack: BackgroundAudioTrackItem?
    private var compositionDuration: CMTime = .zero
    private var isConfiguring = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func configure(track: BackgroundAudioTrackItem?, compositionDuration: CMTime, timelineAsset: AVAsset?) {
        self.currentTrack = track
        self.compositionDuration = compositionDuration
        isConfiguring = true
        defer { isConfiguring = false }

        let hasTrack = track != nil
        trimmerView.isHidden = !hasTrack
        trimmerView.isUserInteractionEnabled = hasTrack
        trimmerView.alpha = hasTrack ? 1 : 0.4
        sourceLabel.isHidden = !hasTrack
        editSourceButton.isHidden = !hasTrack
        editSourceButton.isEnabled = hasTrack
        editSourceButton.alpha = hasTrack ? 1 : 0.4
        addAudioButton.setTitle(hasTrack ? "Replace Audio" : "Add Audio", for: .normal)
        updateButtonStackLayout(hasTrack: hasTrack)

        guard let track else {
            sourceLabel.text = "Set the range where the audio should play"
            return
        }

        trimmerView.asset = timelineAsset
        let compositionRange = CMTimeRange(start: .zero, duration: compositionDuration)
        trimmerView.clipTimeRange = compositionRange
        trimmerView.applySelectionRange(track.timelineTimeRange, clipBounds: compositionRange)
        sourceLabel.text = "Set the range where the audio should play"
    }

    private func setupUI() {
        trimmerView.translatesAutoresizingMaskIntoConstraints = false
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        sourceLabel.font = .systemFont(ofSize: 14, weight: .medium)
        sourceLabel.textColor = UIColor.white.withAlphaComponent(0.45)
        sourceLabel.textAlignment = .center
        sourceLabel.numberOfLines = 2
        sourceLabel.text = "Set the range where the audio should play"
        sourceLabel.isHidden = true

        configureActionButton(addAudioButton, title: "Add Audio", showsPlus: true)
        addAudioButton.addTarget(self, action: #selector(addAudioTapped), for: .touchUpInside)

        configureActionButton(editSourceButton, title: "Trim Audio")
        editSourceButton.addTarget(self, action: #selector(editSourceTapped), for: .touchUpInside)
        editSourceButton.isHidden = true
        editSourceButton.isEnabled = false
        editSourceButton.alpha = 0.4

        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.alignment = .fill
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

        let leading = buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12)
        let trailing = buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12)
        let centerX = buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let addWidth = addAudioButton.widthAnchor.constraint(equalToConstant: 180)
        buttonStackLeadingConstraint = leading
        buttonStackTrailingConstraint = trailing
        buttonStackCenterXConstraint = centerX
        addAudioButtonWidthConstraint = addWidth

        NSLayoutConstraint.activate([
            trimmerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            trimmerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            trimmerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            trimmerView.heightAnchor.constraint(equalToConstant: trimmerHeight),

            sourceLabel.topAnchor.constraint(equalTo: trimmerView.bottomAnchor, constant: 12),
            sourceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            sourceLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            buttonStack.heightAnchor.constraint(equalToConstant: 40),
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            buttonStack.topAnchor.constraint(greaterThanOrEqualTo: sourceLabel.bottomAnchor, constant: 12)
        ])

        updateButtonStackLayout(hasTrack: false)
    }

    private func updateButtonStackLayout(hasTrack: Bool) {
        buttonStack.distribution = hasTrack ? .fillEqually : .fill
        buttonStackLeadingConstraint?.isActive = hasTrack
        buttonStackTrailingConstraint?.isActive = hasTrack
        buttonStackCenterXConstraint?.isActive = !hasTrack
        addAudioButtonWidthConstraint?.isActive = !hasTrack
    }

    private func configureActionButton(_ button: UIButton, title: String, showsPlus: Bool = false) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .clear
        button.tintColor = .white
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor

        if showsPlus {
            let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
            button.semanticContentAttribute = .forceLeftToRight
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
        }
    }

    @objc private func addAudioTapped() {
        requestAddAudio?()
    }

    @objc private func editSourceTapped() {
        guard currentTrack != nil else { return }
        requestEditSource?()
    }

    func recreateThumbnailsFor(asset: AVAsset, videoComposition: AVVideoComposition? = nil) async {
        let compositionRange = CMTimeRange(start: .zero, duration: compositionDuration)
        let selection = currentTrack?.timelineTimeRange

        // Apply asset + selection first so handles aren't stuck at full-width during generation.
        trimmerView.videoComposition = videoComposition
        trimmerView.asset = asset
        trimmerView.clipTimeRange = compositionRange
        if let selection {
            trimmerView.applySelectionRange(selection, clipBounds: compositionRange)
        }

        let _ = await trimmerView.preGenerateImagesWith(trimmerHeight: trimmerHeight)
        trimmerView.regenerateThumbnails()

        if let selection {
            trimmerView.applySelectionRange(selection, clipBounds: compositionRange)
        }
    }
}

extension AudioSectionVC: TrimmerViewDelegate {
    func didChangePositionBar(_ playerTime: CMTime) {}

    func positionBarStoppedMoving(_ playerTime: CMTime) {
        guard !isConfiguring,
              let start = trimmerView.startTime,
              let end = trimmerView.endTime else { return }
        let range = CMTimeRange(start: start, end: end)
        timelineRangeDidChange?(range)
    }
}
