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
        fontName: String,
        fontSize: Double,
        textAlignmentRawValue: Int,
        backgroundStyleRawValue: String,
        strokeColor: UIColor,
        strokeWidth: Double,
        labelFrame: CGRect
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
            fontName: UIFont.systemFont(ofSize: 18).fontName,
            fontSize: 18,
            textAlignmentRawValue: NSTextAlignment.center.rawValue,
            backgroundStyleRawValue: BackgroundStyle.fragmented.rawValue,
            strokeColor: .clear,
            strokeWidth: 0,
            labelFrame: CGRect(x: 0, y: 0, width: 136, height: 24)
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
            center: CGPoint(x: centerX, y: centerY)
        )
        viewModel.width = width
        viewModel.height = height
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
            fontName: viewModel.font.fontName,
            fontSize: Double(viewModel.fontSize),
            textAlignmentRawValue: viewModel.textAlignment.rawValue,
            backgroundStyleRawValue: viewModel.backgroundStyle.rawValue,
            strokeColor: viewModel.strokeColor,
            strokeWidth: Double(viewModel.strokeWidth),
            labelFrame: viewModel.labelFrame
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
