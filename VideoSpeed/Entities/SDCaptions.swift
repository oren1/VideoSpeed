//
//  SDCaptions.swift
//  VideoSpeed
//

import Foundation
import SwiftData
import UIKit
import AVFoundation

/// Codable snapshot of a `Transcription` for SwiftData storage.
struct PersistedTranscription: Codable {
    struct PersistedSegment: Codable {
        let text: String
        let start: Double
        let end: Double
        let words: [Word]
    }

    let text: String
    let words: [Word]?
    let segments: [PersistedSegment]?

    static func encode(_ transcription: Transcription) throws -> Data {
        let persisted = PersistedTranscription(
            text: transcription.text,
            words: transcription.words,
            segments: transcription.segments?.map {
                PersistedSegment(text: $0.text, start: $0.start, end: $0.end, words: $0.words)
            }
        )
        return try JSONEncoder().encode(persisted)
    }

    static func decode(_ data: Data) throws -> Transcription {
        let persisted = try JSONDecoder().decode(PersistedTranscription.self, from: data)
        let segments = persisted.segments?.map {
            Segment(text: $0.text, start: $0.start, end: $0.end, words: $0.words)
        }
        return Transcription(text: persisted.text, words: persisted.words, segments: segments)
    }
}

/// Overlay pose for `CaptionsTextContainer` (persisted with captions).
struct CaptionsOverlayPose {
    var centerX: Double?
    var centerY: Double?
    var fullScale: Double = 1
    var fullRotation: Double = 0

    var center: CGPoint? {
        guard let centerX, let centerY else { return nil }
        return CGPoint(x: centerX, y: centerY)
    }

    static let `default` = CaptionsOverlayPose()
}

@Model
final class SDCaptions {
    var project: VideoProject?
    var transcriptionData: Data

    var captionTypeRawValue: String
    var textColorR: Double
    var textColorG: Double
    var textColorB: Double
    var textColorA: Double
    var borderColorR: Double
    var borderColorG: Double
    var borderColorB: Double
    var borderColorA: Double
    var borderWidth: Double
    var highlightColorR: Double?
    var highlightColorG: Double?
    var highlightColorB: Double?
    var highlightColorA: Double?
    var fontName: String
    var fontSize: Double

    var centerX: Double?
    var centerY: Double?
    var fullScale: Double
    var fullRotation: Double

    init(
        project: VideoProject? = nil,
        transcriptionData: Data,
        captionTypeRawValue: String,
        textColor: UIColor,
        borderColor: UIColor,
        borderWidth: Double,
        highlightColor: UIColor?,
        fontName: String,
        fontSize: Double,
        centerX: Double? = nil,
        centerY: Double? = nil,
        fullScale: Double = 1,
        fullRotation: Double = 0
    ) {
        self.project = project
        self.transcriptionData = transcriptionData
        self.captionTypeRawValue = captionTypeRawValue

        let text = textColor.rgbaComponents()
        self.textColorR = text.r
        self.textColorG = text.g
        self.textColorB = text.b
        self.textColorA = text.a

        let border = borderColor.rgbaComponents()
        self.borderColorR = border.r
        self.borderColorG = border.g
        self.borderColorB = border.b
        self.borderColorA = border.a
        self.borderWidth = borderWidth

        if let highlightColor {
            let highlight = highlightColor.rgbaComponents()
            self.highlightColorR = highlight.r
            self.highlightColorG = highlight.g
            self.highlightColorB = highlight.b
            self.highlightColorA = highlight.a
        } else {
            self.highlightColorR = nil
            self.highlightColorG = nil
            self.highlightColorB = nil
            self.highlightColorA = nil
        }

        self.fontName = fontName
        self.fontSize = fontSize
        self.centerX = centerX
        self.centerY = centerY
        self.fullScale = fullScale
        self.fullRotation = fullRotation
    }

    static func make(
        from transcription: Transcription,
        style: CaptionsStyle,
        pose: CaptionsOverlayPose,
        project: VideoProject?
    ) throws -> SDCaptions {
        SDCaptions(
            project: project,
            transcriptionData: try PersistedTranscription.encode(transcription),
            captionTypeRawValue: style.captionType.rawValue,
            textColor: style.textColor,
            borderColor: style.borderColor,
            borderWidth: Double(style.borderWidth),
            highlightColor: style.highlightColor,
            fontName: style.spidFont.name,
            fontSize: Double(style.fontSize),
            centerX: pose.centerX,
            centerY: pose.centerY,
            fullScale: pose.fullScale,
            fullRotation: pose.fullRotation
        )
    }

    func update(
        from transcription: Transcription,
        style: CaptionsStyle,
        pose: CaptionsOverlayPose
    ) throws {
        transcriptionData = try PersistedTranscription.encode(transcription)
        captionTypeRawValue = style.captionType.rawValue

        let text = style.textColor.rgbaComponents()
        textColorR = text.r
        textColorG = text.g
        textColorB = text.b
        textColorA = text.a

        let border = style.borderColor.rgbaComponents()
        borderColorR = border.r
        borderColorG = border.g
        borderColorB = border.b
        borderColorA = border.a
        borderWidth = Double(style.borderWidth)

        if let highlightColor = style.highlightColor {
            let highlight = highlightColor.rgbaComponents()
            highlightColorR = highlight.r
            highlightColorG = highlight.g
            highlightColorB = highlight.b
            highlightColorA = highlight.a
        } else {
            highlightColorR = nil
            highlightColorG = nil
            highlightColorB = nil
            highlightColorA = nil
        }

        fontName = style.spidFont.name
        fontSize = Double(style.fontSize)
        centerX = pose.centerX
        centerY = pose.centerY
        fullScale = pose.fullScale
        fullRotation = pose.fullRotation
    }

    func makeTranscription() throws -> Transcription {
        try PersistedTranscription.decode(transcriptionData)
    }

    func apply(to style: CaptionsStyle) {
        style.captionType = CaptionsType(rawValue: captionTypeRawValue) ?? .oneWord
        style.textColor = UIColor(red: textColorR, green: textColorG, blue: textColorB, alpha: textColorA)
        style.borderColor = UIColor(red: borderColorR, green: borderColorG, blue: borderColorB, alpha: borderColorA)
        style.borderWidth = CGFloat(borderWidth)
        if let r = highlightColorR, let g = highlightColorG, let b = highlightColorB, let a = highlightColorA {
            style.highlightColor = UIColor(red: r, green: g, blue: b, alpha: a)
        } else {
            style.highlightColor = nil
        }
        style.fontSize = CGFloat(fontSize)
        style.spidFont = SpidFont.font(named: fontName, size: CGFloat(fontSize))
    }

    var overlayPose: CaptionsOverlayPose {
        CaptionsOverlayPose(
            centerX: centerX,
            centerY: centerY,
            fullScale: fullScale,
            fullRotation: fullRotation
        )
    }
}

private extension UIColor {
    func rgbaComponents() -> (r: Double, g: Double, b: Double, a: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if getRed(&r, green: &g, blue: &b, alpha: &a) {
            return (Double(r), Double(g), Double(b), Double(a))
        }
        return (1, 1, 1, 1)
    }
}
