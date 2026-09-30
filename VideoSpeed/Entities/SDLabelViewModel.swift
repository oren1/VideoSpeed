//
//  SDLabelViewModel.swift
//  VideoSpeed
//

import Foundation
import AVFoundation
import SwiftData
import UIKit

@Model
final class SDLabelViewModel {
    @Attribute(.unique) var id: UUID
    var sortIndex: Int
    var project: VideoProject?

    var width: Double
    var height: Double
    var text: String
    var textColorR: Double
    var textColorG: Double
    var textColorB: Double
    var textColorA: Double
    var backgroundColorR: Double
    var backgroundColorG: Double
    var backgroundColorB: Double
    var backgroundColorA: Double
    var centerX: Double
    var centerY: Double
    var scale: Double
    var fullScale: Double
    var rotation: Double
    var fullRotation: Double
    var fontName: String
    var fontSize: Double
    var textAlignmentRawValue: Int
    var backgroundStyleRawValue: String
    var strokeColorR: Double
    var strokeColorG: Double
    var strokeColorB: Double
    var strokeColorA: Double
    var strokeWidth: Double
    var labelFrameWidth: Double
    var labelFrameHeight: Double

    var timeRangeStartValue: Int64?
    var timeRangeStartTimescale: Int32?
    var timeRangeDurationValue: Int64?
    var timeRangeDurationTimescale: Int32?
    var rightHandleConstraintConstant: Double?
    var leftHandleConstraintConstant: Double?
    var selected: Bool
    var isHidden: Bool

    var timeRange: CMTimeRange? {
        get {
            guard
                let startValue = timeRangeStartValue,
                let startTimescale = timeRangeStartTimescale,
                let durationValue = timeRangeDurationValue,
                let durationTimescale = timeRangeDurationTimescale
            else { return nil }
            return CMTimeRange(
                start: CMTime(value: startValue, timescale: startTimescale),
                duration: CMTime(value: durationValue, timescale: durationTimescale)
            )
        }
        set {
            if let newValue {
                timeRangeStartValue = newValue.start.value
                timeRangeStartTimescale = newValue.start.timescale
                timeRangeDurationValue = newValue.duration.value
                timeRangeDurationTimescale = newValue.duration.timescale
            } else {
                timeRangeStartValue = nil
                timeRangeStartTimescale = nil
                timeRangeDurationValue = nil
                timeRangeDurationTimescale = nil
            }
        }
    }

    init(
        id: UUID,
        sortIndex: Int,
        project: VideoProject? = nil,
        width: Double,
        height: Double,
        text: String,
        textColor: UIColor,
        backgroundColor: UIColor,
        center: CGPoint,
        scale: Double = 1,
        fullScale: Double = 1,
        rotation: Double = 0,
        fullRotation: Double = 0,
        fontName: String,
        fontSize: Double,
        textAlignmentRawValue: Int,
        backgroundStyleRawValue: String,
        strokeColor: UIColor,
        strokeWidth: Double,
        labelFrame: CGRect,
        timeRange: CMTimeRange? = nil,
        rightHandleConstraintConstant: Double? = nil,
        leftHandleConstraintConstant: Double? = nil,
        selected: Bool = false,
        isHidden: Bool = false
    ) {
        self.id = id
        self.sortIndex = sortIndex
        self.project = project
        self.width = width
        self.height = height
        self.text = text

        let textComponents = textColor.rgbaComponents()
        self.textColorR = textComponents.r
        self.textColorG = textComponents.g
        self.textColorB = textComponents.b
        self.textColorA = textComponents.a

        let backgroundComponents = backgroundColor.rgbaComponents()
        self.backgroundColorR = backgroundComponents.r
        self.backgroundColorG = backgroundComponents.g
        self.backgroundColorB = backgroundComponents.b
        self.backgroundColorA = backgroundComponents.a

        self.centerX = center.x
        self.centerY = center.y
        self.scale = scale
        self.fullScale = fullScale
        self.rotation = rotation
        self.fullRotation = fullRotation
        self.fontName = fontName
        self.fontSize = fontSize
        self.textAlignmentRawValue = textAlignmentRawValue
        self.backgroundStyleRawValue = backgroundStyleRawValue

        let strokeComponents = strokeColor.rgbaComponents()
        self.strokeColorR = strokeComponents.r
        self.strokeColorG = strokeComponents.g
        self.strokeColorB = strokeComponents.b
        self.strokeColorA = strokeComponents.a
        self.strokeWidth = strokeWidth

        self.labelFrameWidth = labelFrame.width
        self.labelFrameHeight = labelFrame.height

        if let timeRange {
            self.timeRangeStartValue = timeRange.start.value
            self.timeRangeStartTimescale = timeRange.start.timescale
            self.timeRangeDurationValue = timeRange.duration.value
            self.timeRangeDurationTimescale = timeRange.duration.timescale
        } else {
            self.timeRangeStartValue = nil
            self.timeRangeStartTimescale = nil
            self.timeRangeDurationValue = nil
            self.timeRangeDurationTimescale = nil
        }
        self.rightHandleConstraintConstant = rightHandleConstraintConstant
        self.leftHandleConstraintConstant = leftHandleConstraintConstant
        self.selected = selected
        self.isHidden = isHidden
    }

    static func makeMock() -> SDLabelViewModel {
        SDLabelViewModel(
            id: UUID(),
            sortIndex: 0,
            width: 160,
            height: 48,
            text: "Mock Text",
            textColor: .white,
            backgroundColor: UIColor.black.withAlphaComponent(0.6),
            center: .zero,
            scale: 1,
            fullScale: 1,
            rotation: 0,
            fullRotation: 0,
            fontName: UIFont.systemFont(ofSize: 18).fontName,
            fontSize: 18,
            textAlignmentRawValue: NSTextAlignment.center.rawValue,
            backgroundStyleRawValue: BackgroundStyle.fragmented.rawValue,
            strokeColor: .clear,
            strokeWidth: 0,
            labelFrame: CGRect(x: 0, y: 0, width: 136, height: 24),
            timeRange: nil,
            rightHandleConstraintConstant: nil,
            leftHandleConstraintConstant: nil,
            selected: false,
            isHidden: false
        )
    }

    func makeLabelViewModel() -> LabelViewModel {
        let viewModel = LabelViewModel(
            id: id,
            labelFrame: CGRect(x: 0, y: 0, width: labelFrameWidth, height: labelFrameHeight),
            text: text,
            textColor: UIColor(red: textColorR, green: textColorG, blue: textColorB, alpha: textColorA),
            backgroundColor: UIColor(
                red: backgroundColorR,
                green: backgroundColorG,
                blue: backgroundColorB,
                alpha: backgroundColorA
            ),
            textAlignment: NSTextAlignment(rawValue: textAlignmentRawValue) ?? .center,
            center: CGPoint(x: centerX, y: centerY),
            rotation: rotation,
            timeRange: timeRange,
            selected: selected
        )
        viewModel.width = width
        viewModel.height = height
        viewModel.scale = scale
        viewModel.fullScale = fullScale
        viewModel.fullRotation = fullRotation
        viewModel.fontSize = fontSize
        viewModel.font = UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        viewModel.backgroundStyle = BackgroundStyle(rawValue: backgroundStyleRawValue) ?? .fragmented
        viewModel.strokeColor = UIColor(
            red: strokeColorR,
            green: strokeColorG,
            blue: strokeColorB,
            alpha: strokeColorA
        )
        viewModel.strokeWidth = strokeWidth
        viewModel.rightHandleConstraintConstant = rightHandleConstraintConstant.map { CGFloat($0) }
        viewModel.leftHandleConstraintConstant = leftHandleConstraintConstant.map { CGFloat($0) }
        viewModel.isHidden = isHidden
        return viewModel
    }

    static func make(from viewModel: LabelViewModel, sortIndex: Int, project: VideoProject? = nil) -> SDLabelViewModel {
        SDLabelViewModel(
            id: viewModel.id,
            sortIndex: sortIndex,
            project: project,
            width: Double(viewModel.width),
            height: Double(viewModel.height),
            text: viewModel.text,
            textColor: viewModel.textColor,
            backgroundColor: viewModel.backgroundColor,
            center: viewModel.center,
            scale: Double(viewModel.scale),
            fullScale: Double(viewModel.fullScale),
            rotation: Double(viewModel.rotation),
            fullRotation: Double(viewModel.fullRotation),
            fontName: viewModel.font.fontName,
            fontSize: Double(viewModel.fontSize),
            textAlignmentRawValue: viewModel.textAlignment.rawValue,
            backgroundStyleRawValue: viewModel.backgroundStyle.rawValue,
            strokeColor: viewModel.strokeColor,
            strokeWidth: Double(viewModel.strokeWidth),
            labelFrame: viewModel.labelFrame,
            timeRange: viewModel.timeRange,
            rightHandleConstraintConstant: viewModel.rightHandleConstraintConstant.map { Double($0) },
            leftHandleConstraintConstant: viewModel.leftHandleConstraintConstant.map { Double($0) },
            selected: viewModel.selected,
            isHidden: viewModel.isHidden
        )
    }

    func update(from viewModel: LabelViewModel, sortIndex: Int) {
        self.sortIndex = sortIndex
        self.width = Double(viewModel.width)
        self.height = Double(viewModel.height)
        self.text = viewModel.text

        let textComponents = viewModel.textColor.rgbaComponents()
        self.textColorR = textComponents.r
        self.textColorG = textComponents.g
        self.textColorB = textComponents.b
        self.textColorA = textComponents.a

        let backgroundComponents = viewModel.backgroundColor.rgbaComponents()
        self.backgroundColorR = backgroundComponents.r
        self.backgroundColorG = backgroundComponents.g
        self.backgroundColorB = backgroundComponents.b
        self.backgroundColorA = backgroundComponents.a

        self.centerX = viewModel.center.x
        self.centerY = viewModel.center.y
        self.scale = Double(viewModel.scale)
        self.fullScale = Double(viewModel.fullScale)
        self.rotation = Double(viewModel.rotation)
        self.fullRotation = Double(viewModel.fullRotation)
        self.fontName = viewModel.font.fontName
        self.fontSize = Double(viewModel.fontSize)
        self.textAlignmentRawValue = viewModel.textAlignment.rawValue
        self.backgroundStyleRawValue = viewModel.backgroundStyle.rawValue

        let strokeComponents = viewModel.strokeColor.rgbaComponents()
        self.strokeColorR = strokeComponents.r
        self.strokeColorG = strokeComponents.g
        self.strokeColorB = strokeComponents.b
        self.strokeColorA = strokeComponents.a
        self.strokeWidth = Double(viewModel.strokeWidth)

        self.labelFrameWidth = viewModel.labelFrame.width
        self.labelFrameHeight = viewModel.labelFrame.height

        self.timeRange = viewModel.timeRange
        self.rightHandleConstraintConstant = viewModel.rightHandleConstraintConstant.map { Double($0) }
        self.leftHandleConstraintConstant = viewModel.leftHandleConstraintConstant.map { Double($0) }
        self.selected = viewModel.selected
        self.isHidden = viewModel.isHidden
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
