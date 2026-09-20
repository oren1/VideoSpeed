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
    var fontSize: Double
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
        fontSize: Double,
        labelFrame: CGRect
    ) {
        self.id = id
        self.sortIndex = sortIndex
        self.project = project
        self.width = width
        self.height = height
        self.text = text

        var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0, ta: CGFloat = 0
        textColor.getRed(&tr, green: &tg, blue: &tb, alpha: &ta)
        self.textColorR = Double(tr)
        self.textColorG = Double(tg)
        self.textColorB = Double(tb)
        self.textColorA = Double(ta)

        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        backgroundColor.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        self.backgroundColorR = Double(br)
        self.backgroundColorG = Double(bg)
        self.backgroundColorB = Double(bb)
        self.backgroundColorA = Double(ba)

        self.centerX = center.x
        self.centerY = center.y
        self.fontSize = fontSize
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
            fontSize: 18,
            labelFrame: CGRect(x: 0, y: 0, width: 136, height: 24)
        )
    }

    func makeLabelViewModel() -> LabelViewModel {
        LabelViewModel(
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
            textAlignment: .center,
            center: CGPoint(x: centerX, y: centerY)
        )
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
            fontSize: Double(viewModel.fontSize),
            labelFrame: viewModel.labelFrame
        )
    }

    func update(from viewModel: LabelViewModel, sortIndex: Int) {
        self.sortIndex = sortIndex
        self.width = Double(viewModel.width)
        self.height = Double(viewModel.height)
        self.text = viewModel.text

        var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0, ta: CGFloat = 0
        viewModel.textColor.getRed(&tr, green: &tg, blue: &tb, alpha: &ta)
        self.textColorR = Double(tr)
        self.textColorG = Double(tg)
        self.textColorB = Double(tb)
        self.textColorA = Double(ta)

        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        viewModel.backgroundColor.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        self.backgroundColorR = Double(br)
        self.backgroundColorG = Double(bg)
        self.backgroundColorB = Double(bb)
        self.backgroundColorA = Double(ba)

        self.centerX = viewModel.center.x
        self.centerY = viewModel.center.y
        self.fontSize = Double(viewModel.fontSize)
        self.labelFrameWidth = viewModel.labelFrame.width
        self.labelFrameHeight = viewModel.labelFrame.height
    }
}
