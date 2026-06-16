//
//  FilterCompositor.swift
//  VideoSpeed
//

import AVFoundation
import CoreImage
import UIKit

enum VideoFilter: String, CaseIterable, Identifiable {
    case none
    case sepia
    case noir
    case mono
    case fade
    case chrome
    case process
    case tonal
    case transfer
    case instant
    case vibrant
    case warm
    case cool
    case highContrast
    case lowSaturation
    case highSaturation
    case bright
    case dark
    case gammaBoost
    case hueShift
    case vignette
    case sharpen
    case bloom
    case pixellate
    case comic
    case invert
    case posterize
    case dotScreen
    case crystallize
    case edgeDetect

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: "Original"
        case .sepia: "Sepia"
        case .noir: "Noir"
        case .mono: "Mono"
        case .fade: "Fade"
        case .chrome: "Chrome"
        case .process: "Process"
        case .tonal: "Tonal"
        case .transfer: "Transfer"
        case .instant: "Instant"
        case .vibrant: "Vibrant"
        case .warm: "Warm"
        case .cool: "Cool"
        case .highContrast: "High Contrast"
        case .lowSaturation: "Muted"
        case .highSaturation: "Saturated"
        case .bright: "Bright"
        case .dark: "Dark"
        case .gammaBoost: "Gamma Boost"
        case .hueShift: "Hue Shift"
        case .vignette: "Vignette"
        case .sharpen: "Sharpen"
        case .bloom: "Bloom"
        case .pixellate: "Pixelate"
        case .comic: "Comic"
        case .invert: "Invert"
        case .posterize: "Posterize"
        case .dotScreen: "Dot Screen"
        case .crystallize: "Crystallize"
        case .edgeDetect: "Edge Detect"
        }
    }

    var usesCustomCompositor: Bool {
        self != .none
    }
}

class FilterCompositor: NSObject, AVVideoCompositing {

    static var trackFilters: [CMPersistentTrackID: VideoFilter] = [:]

    var sourcePixelBufferAttributes: [String: Any]? = [
        kCVPixelBufferPixelFormatTypeKey as String: [kCVPixelFormatType_32BGRA]
    ]

    var requiredPixelBufferAttributesForRenderContext: [String: Any] = [
        kCVPixelBufferPixelFormatTypeKey as String: [kCVPixelFormatType_32BGRA]
    ]

    private let ciContext = CIContext()

    // MARK: - Filter Dictionary

    private typealias FilterApplicator = (CIImage) -> CIImage?

    private static let filterApplicators: [VideoFilter: FilterApplicator] = [
        .none: { $0 },

        .sepia: applyFilter(named: "CISepiaTone") { filter, _ in
            filter.setValue(0.85, forKey: kCIInputIntensityKey)
        },

        .noir: applyFilter(named: "CIPhotoEffectNoir"),
        .mono: applyFilter(named: "CIPhotoEffectMono"),
        .fade: applyFilter(named: "CIPhotoEffectFade"),
        .chrome: applyFilter(named: "CIPhotoEffectChrome"),
        .process: applyFilter(named: "CIPhotoEffectProcess"),
        .tonal: applyFilter(named: "CIPhotoEffectTonal"),
        .transfer: applyFilter(named: "CIPhotoEffectTransfer"),
        .instant: applyFilter(named: "CIPhotoEffectInstant"),

        .vibrant: applyFilter(named: "CIVibrance") { filter, _ in
            filter.setValue(0.75, forKey: "inputAmount")
        },

        .warm: applyFilter(named: "CITemperatureAndTint") { filter, _ in
            filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            filter.setValue(CIVector(x: 7200, y: 0), forKey: "inputTargetNeutral")
        },

        .cool: applyFilter(named: "CITemperatureAndTint") { filter, _ in
            filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            filter.setValue(CIVector(x: 5200, y: 0), forKey: "inputTargetNeutral")
        },

        .highContrast: applyFilter(named: "CIColorControls") { filter, _ in
            filter.setValue(1.35, forKey: kCIInputContrastKey)
            filter.setValue(1.05, forKey: kCIInputSaturationKey)
        },

        .lowSaturation: applyFilter(named: "CIColorControls") { filter, _ in
            filter.setValue(0.35, forKey: kCIInputSaturationKey)
            filter.setValue(1.05, forKey: kCIInputContrastKey)
        },

        .highSaturation: applyFilter(named: "CIColorControls") { filter, _ in
            filter.setValue(1.75, forKey: kCIInputSaturationKey)
        },

        .bright: applyFilter(named: "CIExposureAdjust") { filter, _ in
            filter.setValue(0.65, forKey: kCIInputEVKey)
        },

        .dark: applyFilter(named: "CIExposureAdjust") { filter, _ in
            filter.setValue(-0.75, forKey: kCIInputEVKey)
        },

        .gammaBoost: applyFilter(named: "CIGammaAdjust") { filter, _ in
            filter.setValue(0.72, forKey: "inputPower")
        },

        .hueShift: applyFilter(named: "CIHueAdjust") { filter, _ in
            filter.setValue(CGFloat.pi / 6, forKey: kCIInputAngleKey)
        },

        .vignette: applyFilter(named: "CIVignette") { filter, _ in
            filter.setValue(1.4, forKey: kCIInputIntensityKey)
            filter.setValue(1.8, forKey: kCIInputRadiusKey)
        },

        .sharpen: applyFilter(named: "CISharpenLuminance") { filter, _ in
            filter.setValue(0.85, forKey: kCIInputSharpnessKey)
        },

        .bloom: applyClippedFilter(named: "CIBloom") { filter, _ in
            filter.setValue(0.55, forKey: kCIInputIntensityKey)
            filter.setValue(12, forKey: kCIInputRadiusKey)
        },

        .pixellate: applyFilter(named: "CIPixellate") { filter, inputImage in
            filter.setValue(12, forKey: kCIInputScaleKey)
            filter.setValue(CIVector(x: inputImage.extent.midX, y: inputImage.extent.midY), forKey: kCIInputCenterKey)
        },

        .comic: applyFilter(named: "CIComicEffect"),

        .invert: applyFilter(named: "CIColorInvert"),

        .posterize: applyFilter(named: "CIColorPosterize") { filter, _ in
            filter.setValue(6, forKey: "inputLevels")
        },

        .dotScreen: applyFilter(named: "CIDotScreen") { filter, inputImage in
            filter.setValue(6, forKey: kCIInputWidthKey)
            filter.setValue(0.7, forKey: kCIInputSharpnessKey)
            filter.setValue(CIVector(x: inputImage.extent.midX, y: inputImage.extent.midY), forKey: kCIInputCenterKey)
        },

        .crystallize: applyFilter(named: "CICrystallize") { filter, inputImage in
            filter.setValue(18, forKey: kCIInputRadiusKey)
            filter.setValue(CIVector(x: inputImage.extent.midX, y: inputImage.extent.midY), forKey: kCIInputCenterKey)
        },

        .edgeDetect: applyFilter(named: "CIEdges") { filter, _ in
            filter.setValue(4, forKey: kCIInputIntensityKey)
        },
    ]

    static func apply(_ filter: VideoFilter, to inputImage: CIImage) -> CIImage {
        filterApplicators[filter]?(inputImage) ?? inputImage
    }

    static func previewImage(for filter: VideoFilter, from cgImage: CGImage, context: CIContext) -> UIImage? {
        let inputImage = CIImage(cgImage: cgImage)
        let outputImage = apply(filter, to: inputImage)
        guard let renderedImage = context.createCGImage(outputImage, from: inputImage.extent) else {
            return nil
        }
        return UIImage(cgImage: renderedImage)
    }

    private static func applyFilter(
        named name: String,
        configure: ((CIFilter, CIImage) -> Void)? = nil
    ) -> FilterApplicator {
        { inputImage in
            guard let filter = CIFilter(name: name) else { return inputImage }
            filter.setValue(inputImage, forKey: kCIInputImageKey)
            configure?(filter, inputImage)
            return filter.outputImage ?? inputImage
        }
    }

    /// For filters that expand the image extent (blur, bloom, etc.) — crop back to source bounds.
    private static func applyClippedFilter(
        named name: String,
        configure: ((CIFilter, CIImage) -> Void)? = nil
    ) -> FilterApplicator {
        { inputImage in
            guard let filter = CIFilter(name: name) else { return inputImage }
            filter.setValue(inputImage, forKey: kCIInputImageKey)
            configure?(filter, inputImage)
            return filter.outputImage?.cropped(to: inputImage.extent) ?? inputImage
        }
    }

    // MARK: - AVVideoCompositing

    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {}

    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        guard let instruction = asyncVideoCompositionRequest.videoCompositionInstruction as? AVVideoCompositionInstruction else {
            asyncVideoCompositionRequest.finish(with: NSError(domain: "FilterCompositor", code: -1))
            return
        }

        guard let outputPixelBuffer = asyncVideoCompositionRequest.renderContext.newPixelBuffer() else {
            asyncVideoCompositionRequest.finish(with: NSError(domain: "FilterCompositor", code: -2))
            return
        }

        let renderBounds = CGRect(origin: .zero, size: asyncVideoCompositionRequest.renderContext.size)
        var composedImage: CIImage?

        for layerInstruction in instruction.layerInstructions {
            guard let sourcePixelBuffer = asyncVideoCompositionRequest.sourceFrame(byTrackID: layerInstruction.trackID) else {
                continue
            }

            var inputImage = CIImage(cvPixelBuffer: sourcePixelBuffer)

            var transform = CGAffineTransform.identity
            layerInstruction.getTransformRamp(
                for: asyncVideoCompositionRequest.compositionTime,
                start: &transform,
                end: nil,
                timeRange: nil
            )
            inputImage = inputImage.transformed(by: transform)

            if let filteredImage = applyFilter(to: inputImage, trackID: layerInstruction.trackID) {
                composedImage = filteredImage
            }
        }

        guard let outputImage = composedImage else {
            asyncVideoCompositionRequest.finish(with: NSError(domain: "FilterCompositor", code: -3))
            return
        }

        ciContext.render(
            outputImage,
            to: outputPixelBuffer,
            bounds: renderBounds,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        asyncVideoCompositionRequest.finish(withComposedVideoFrame: outputPixelBuffer)
    }

    private func applyFilter(to inputImage: CIImage, trackID: CMPersistentTrackID) -> CIImage? {
        let filter = Self.trackFilters[trackID] ?? .none
        guard filter != .none else { return inputImage }
        return Self.filterApplicators[filter]?(inputImage) ?? inputImage
    }
}
