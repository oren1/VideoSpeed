//
//  CaptionsTemplatePreviewView.swift
//  VideoSpeed
//
//  Created by Codex on 21/04/2026.
//

import SwiftUI

struct CaptionsTemplatePreviewView: View {
    private let previewWidth: CGFloat = 100
    private let previewHeight: CGFloat = 100

    let captionsType: CaptionsType
    let transcription: Transcription
    @State private var captions: [Caption] = []
    @State private var displayedCaption: Caption?
    @State private var currentTime: Double = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            Color.clear
            AttributedText(
                attributedString: displayedCaption?.text ?? NSAttributedString(string: previewText)
            )
            .background(Color.black)
            .frame(width: previewWidth, height: previewHeight)
            .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard let segments = transcription.segments else {
                return
            }

            switch captionsType {
            case .oneWord:
                captions = CaptionStyleGenerator.generateOneWordCaptions(from: segments, scale: 0.5)
            case .wordByWord:
                captions = CaptionStyleGenerator.generateOneByOneCaptions(from: segments, scale: 0.5)
            case .wordHighlighted:
                captions = CaptionStyleGenerator.generateWordHighlightCaptions(from: segments,scale: 0.5)
            }

            currentTime = 0
            updateCaptionForCurrentTime()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private var previewText: String {
        if let firstCaption = captions.first {
            return firstCaption.text.string
        }
        return transcription.text
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            currentTime += 0.1
            updateCaptionForCurrentTime()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateCaptionForCurrentTime() {
        guard !captions.isEmpty else {
            displayedCaption = nil
            return
        }

        if currentTime > (captions.last?.endTime ?? 0) {
            currentTime = 0
        }

        displayedCaption = CaptionStyleGenerator.getCurrentCaption(
            captions: captions,
            time: currentTime
        )
    }
}

#Preview {
    CaptionsTemplatePreviewView(
        captionsType: .wordHighlighted,
        transcription: Segment.demoTranscription()
    )
}


struct AttributedText: UIViewRepresentable {
    
    let attributedString: NSAttributedString
    
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.backgroundColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.1
        label.lineBreakMode = .byWordWrapping
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = attributedString.oneWordPerLine()
    }
}

private extension NSAttributedString {
    func oneWordPerLine() -> NSAttributedString {
        let result = NSMutableAttributedString()
        let fullText = string as NSString
        let wordRange = NSRange(location: 0, length: fullText.length)
        var isFirstWord = true

        fullText.enumerateSubstrings(in: wordRange, options: .byWords) { _, range, _, _ in
            if !isFirstWord {
                result.append(NSAttributedString(string: "\n"))
            }
            isFirstWord = false
            result.append(self.attributedSubstring(from: range))
        }

        if result.length == 0 {
            return self
        }

        return result
    }
}
