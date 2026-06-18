//
//  FilterCompositor.swift
//  VideoSpeed
//

import AVFoundation
import CoreImage
import UIKit

enum VideoFilter: String, CaseIterable, Identifiable {
    // Original
    case none

    // Natural (preview group — shown first)
    case naturalBalanced
    case naturalRosy
    case naturalFresh
    case naturalClean
    case naturalLush

    // Photo Effects
    case noir
    case mono
    case fade
    case chrome
    case process
    case tonal
    case transfer
    case instant

    // Vintage
    case sepia
    case sepiaLight
    case sepiaHeavy
    case vintageWarm
    case vintageCool
    case agedFilm

    // Temperature
    case warm
    case warmer
    case warmest
    case cool
    case cooler
    case coolest
    case goldenHour
    case arcticBlue

    // Exposure
    case bright
    case brighter
    case dark
    case darker
    case exposureBoost
    case exposureCrush
    case highlightBoost
    case shadowLift

    // Color Tuning
    case vibrant
    case saturated
    case hyperSaturated
    case muted
    case desaturated
    case highContrast
    case lowContrast
    case punchy
    case fadedColor

    // Hue
    case hueShift15
    case hueShift30
    case hueShift60
    case hueShift90
    case hueShift120
    case hueShift180

    // Gamma
    case gammaBoost
    case gammaCrush
    case gammaLight
    case gammaDark

    // Blur & Glow
    case bloomSoft
    case bloom
    case bloomStrong
    case gaussianBlurSoft
    case gaussianBlur
    case gaussianBlurStrong
    case motionBlur
    case zoomBlur

    // Vignette
    case vignetteSoft
    case vignette
    case vignetteStrong
    case vividVignette

    // Pixel & Mosaic
    case pixellateFine
    case pixellate
    case pixellateCoarse
    case hexagonalPixellate
    case crystallizeFine
    case crystallize

    // Halftone
    case dotScreen
    case lineScreen
    case circularScreen

    // Edges & Sketch
    case edgeDetect
    case edgeWork
    case sketch
    case comic

    // Posterize
    case posterizeLight
    case posterize
    case posterizeHeavy
    case colorQuantize

    // Invert & Monochrome
    case invert
    case falseColor
    case monochromeRed
    case monochromeBlue

    case gloom

    // Distortion
    case bumpDistortion
    case pinch
    case twirl
    case vortex
    case glassDistortion
    case holeDistortion

    // Texture
    case noiseReduction
    case speckle
    case pointillize
    case crystallizeHeavy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: "Original"
        case .naturalBalanced: "Balanced"
        case .naturalRosy: "Rosy"
        case .naturalFresh: "Fresh"
        case .naturalClean: "Clean"
        case .naturalLush: "Lush"
        case .noir: "Noir"
        case .mono: "Mono"
        case .fade: "Fade"
        case .chrome: "Chrome"
        case .process: "Process"
        case .tonal: "Tonal"
        case .transfer: "Transfer"
        case .instant: "Instant"
        case .sepia: "Sepia"
        case .sepiaLight: "Sepia Light"
        case .sepiaHeavy: "Sepia Heavy"
        case .vintageWarm: "Vintage Warm"
        case .vintageCool: "Vintage Cool"
        case .agedFilm: "Aged Film"
        case .warm: "Warm"
        case .warmer: "Warmer"
        case .warmest: "Warmest"
        case .cool: "Cool"
        case .cooler: "Cooler"
        case .coolest: "Coolest"
        case .goldenHour: "Golden Hour"
        case .arcticBlue: "Arctic Blue"
        case .bright: "Bright"
        case .brighter: "Brighter"
        case .dark: "Dark"
        case .darker: "Darker"
        case .exposureBoost: "Boost"
        case .exposureCrush: "Crush"
        case .highlightBoost: "Highlights"
        case .shadowLift: "Shadows"
        case .vibrant: "Vibrant"
        case .saturated: "Saturated"
        case .hyperSaturated: "Hyper Sat"
        case .muted: "Muted"
        case .desaturated: "Desaturated"
        case .highContrast: "High Contrast"
        case .lowContrast: "Low Contrast"
        case .punchy: "Punchy"
        case .fadedColor: "Faded"
        case .hueShift15: "Hue +15°"
        case .hueShift30: "Hue +30°"
        case .hueShift60: "Hue +60°"
        case .hueShift90: "Hue +90°"
        case .hueShift120: "Hue +120°"
        case .hueShift180: "Hue +180°"
        case .gammaBoost: "Gamma Boost"
        case .gammaCrush: "Gamma Crush"
        case .gammaLight: "Gamma Light"
        case .gammaDark: "Gamma Dark"
        case .bloomSoft: "Bloom Soft"
        case .bloom: "Bloom"
        case .bloomStrong: "Bloom Strong"
        case .gaussianBlurSoft: "Blur Soft"
        case .gaussianBlur: "Blur"
        case .gaussianBlurStrong: "Blur Strong"
        case .motionBlur: "Motion Blur"
        case .zoomBlur: "Zoom Blur"
        case .vignetteSoft: "Vignette Soft"
        case .vignette: "Vignette"
        case .vignetteStrong: "Vignette Strong"
        case .vividVignette: "Vivid Vignette"
        case .pixellateFine: "Pixel Fine"
        case .pixellate: "Pixelate"
        case .pixellateCoarse: "Pixel Coarse"
        case .hexagonalPixellate: "Hex Pixel"
        case .crystallizeFine: "Crystal Fine"
        case .crystallize: "Crystallize"
        case .dotScreen: "Dot Screen"
        case .lineScreen: "Line Screen"
        case .circularScreen: "Circular"
        case .edgeDetect: "Edges"
        case .edgeWork: "Edge Work"
        case .sketch: "Sketch"
        case .comic: "Comic"
        case .posterizeLight: "Poster Light"
        case .posterize: "Posterize"
        case .posterizeHeavy: "Poster Heavy"
        case .colorQuantize: "Quantize"
        case .invert: "Invert"
        case .falseColor: "False Color"
        case .monochromeRed: "Mono Red"
        case .monochromeBlue: "Mono Blue"
        case .gloom: "Gloom"
        case .bumpDistortion: "Bump"
        case .pinch: "Pinch"
        case .twirl: "Twirl"
        case .vortex: "Vortex"
        case .glassDistortion: "Glass"
        case .holeDistortion: "Hole"
        case .noiseReduction: "Denoise"
        case .speckle: "Speckle"
        case .pointillize: "Pointillize"
        case .crystallizeHeavy: "Crystal Heavy"
        }
    }

    var usesCustomCompositor: Bool {
        self != .none
    }

    static let naturalFilters: [VideoFilter] = [
        .naturalBalanced,
        .naturalRosy,
        .naturalFresh,
        .naturalClean,
        .naturalLush,
    ]

    static var displayOrder: [VideoFilter] {
        var ordered: [VideoFilter] = [.none]
        ordered.append(contentsOf: naturalFilters)
        let grouped = Set(naturalFilters)
        ordered.append(contentsOf: allCases.filter { $0 != .none && !grouped.contains($0) })
        return ordered
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

    private static let filterApplicators: [VideoFilter: FilterApplicator] = {
        var map: [VideoFilter: FilterApplicator] = [:]

        map[.none] = { $0 }

        // Natural — subtle, close-to-original looks
        map[.naturalBalanced] = { input in
            let adjusted = colorControls(brightness: 0.01, saturation: 1.02, contrast: 1.03)(input) ?? input
            return applyFilter(named: "CIVibrance") { filter, _ in
                filter.setValue(0.12, forKey: "inputAmount")
            }(adjusted) ?? adjusted
        }
        map[.naturalRosy] = { input in
            let adjusted = temperature(targetKelvin: 7000)(input) ?? input
            return colorControls(brightness: 0.02, saturation: 1.05)(adjusted) ?? adjusted
        }
        map[.naturalFresh] = { input in
            let adjusted = temperature(targetKelvin: 6100)(input) ?? input
            return applyFilter(named: "CIVibrance") { filter, _ in
                filter.setValue(0.18, forKey: "inputAmount")
            }(adjusted) ?? adjusted
        }
        map[.naturalClean] = colorControls(brightness: 0.01, saturation: 1.03, contrast: 1.06)
        map[.naturalLush] = { input in
            let adjusted = applyFilter(named: "CIVibrance") { filter, _ in
                filter.setValue(0.28, forKey: "inputAmount")
            }(input) ?? input
            return colorControls(saturation: 1.06, contrast: 1.04)(adjusted) ?? adjusted
        }

        // Photo Effects
        map[.noir] = applyFilter(named: "CIPhotoEffectNoir")
        map[.mono] = applyFilter(named: "CIPhotoEffectMono")
        map[.fade] = applyFilter(named: "CIPhotoEffectFade")
        map[.chrome] = applyFilter(named: "CIPhotoEffectChrome")
        map[.process] = applyFilter(named: "CIPhotoEffectProcess")
        map[.tonal] = applyFilter(named: "CIPhotoEffectTonal")
        map[.transfer] = applyFilter(named: "CIPhotoEffectTransfer")
        map[.instant] = applyFilter(named: "CIPhotoEffectInstant")

        // Vintage
        map[.sepia] = applyFilter(named: "CISepiaTone") { filter, _ in
            filter.setValue(0.85, forKey: kCIInputIntensityKey)
        }
        map[.sepiaLight] = applyFilter(named: "CISepiaTone") { filter, _ in
            filter.setValue(0.45, forKey: kCIInputIntensityKey)
        }
        map[.sepiaHeavy] = applyFilter(named: "CISepiaTone") { filter, _ in
            filter.setValue(1.0, forKey: kCIInputIntensityKey)
        }

        // Temperature
        map[.warm] = temperature(targetKelvin: 7000)
        map[.warmer] = temperature(targetKelvin: 7500)
        map[.warmest] = temperature(targetKelvin: 8200)
        map[.cool] = temperature(targetKelvin: 5500)
        map[.cooler] = temperature(targetKelvin: 5000)
        map[.coolest] = temperature(targetKelvin: 4500)

        // Exposure
        map[.bright] = exposure(0.45)
        map[.brighter] = exposure(0.75)
        map[.dark] = exposure(-0.45)
        map[.darker] = exposure(-0.85)
        map[.exposureBoost] = exposure(1.0)
        map[.exposureCrush] = exposure(-1.2)
        map[.highlightBoost] = highlightShadow(highlight: 0.85, shadow: 0.0)
        map[.shadowLift] = highlightShadow(highlight: 0.0, shadow: 0.65)

        // Color Tuning
        map[.vibrant] = applyFilter(named: "CIVibrance") { filter, _ in
            filter.setValue(0.75, forKey: "inputAmount")
        }
        map[.saturated] = colorControls(saturation: 1.45)
        map[.hyperSaturated] = colorControls(saturation: 1.9, contrast: 1.1)
        map[.muted] = colorControls(saturation: 0.45, contrast: 1.05)
        map[.desaturated] = colorControls(saturation: 0.15)
        map[.highContrast] = colorControls(saturation: 1.05, contrast: 1.4)
        map[.lowContrast] = colorControls(saturation: 0.95, contrast: 0.7)
        map[.punchy] = colorControls(brightness: 0.02, saturation: 1.35, contrast: 1.25)

        // Hue
        map[.hueShift15] = hue(.pi / 12)
        map[.hueShift30] = hue(.pi / 6)
        map[.hueShift60] = hue(.pi / 3)
        map[.hueShift90] = hue(.pi / 2)
        map[.hueShift120] = hue(2 * .pi / 3)
        map[.hueShift180] = hue(.pi)

        // Gamma
        map[.gammaBoost] = gamma(0.72)
        map[.gammaCrush] = gamma(1.35)
        map[.gammaLight] = gamma(0.85)
        map[.gammaDark] = gamma(1.15)

        // Blur & Glow
        map[.bloomSoft] = applyClippedFilter(named: "CIBloom") { filter, _ in
            filter.setValue(0.35, forKey: kCIInputIntensityKey)
            filter.setValue(8, forKey: kCIInputRadiusKey)
        }
        map[.bloom] = applyClippedFilter(named: "CIBloom") { filter, _ in
            filter.setValue(0.55, forKey: kCIInputIntensityKey)
            filter.setValue(12, forKey: kCIInputRadiusKey)
        }
        map[.bloomStrong] = applyClippedFilter(named: "CIBloom") { filter, _ in
            filter.setValue(0.85, forKey: kCIInputIntensityKey)
            filter.setValue(18, forKey: kCIInputRadiusKey)
        }
        map[.gaussianBlurSoft] = applyClippedFilter(named: "CIGaussianBlur") { filter, _ in
            filter.setValue(2, forKey: kCIInputRadiusKey)
        }
        map[.gaussianBlur] = applyClippedFilter(named: "CIGaussianBlur") { filter, _ in
            filter.setValue(5, forKey: kCIInputRadiusKey)
        }
        map[.gaussianBlurStrong] = applyClippedFilter(named: "CIGaussianBlur") { filter, _ in
            filter.setValue(10, forKey: kCIInputRadiusKey)
        }
        map[.motionBlur] = applyClippedFilter(named: "CIMotionBlur") { filter, _ in
            filter.setValue(12, forKey: kCIInputRadiusKey)
            filter.setValue(0, forKey: kCIInputAngleKey)
        }
        map[.zoomBlur] = applyClippedFilter(named: "CIZoomBlur") { filter, inputImage in
            filter.setValue(12, forKey: kCIInputAmountKey)
            filter.setValue(center(inputImage), forKey: kCIInputCenterKey)
        }

        // Vignette
        map[.vignetteSoft] = vignette(intensity: 0.8, radius: 1.4)
        map[.vignette] = vignette(intensity: 1.4, radius: 1.8)
        map[.vignetteStrong] = vignette(intensity: 2.0, radius: 2.2)

        // Pixel & Mosaic
        map[.pixellateFine] = pixellate(scale: 6)
        map[.pixellate] = pixellate(scale: 12)
        map[.pixellateCoarse] = pixellate(scale: 24)
        map[.hexagonalPixellate] = applyFilter(named: "CIHexagonalPixellate") { filter, inputImage in
            filter.setValue(8, forKey: kCIInputScaleKey)
            filter.setValue(center(inputImage), forKey: kCIInputCenterKey)
        }
        map[.crystallizeFine] = crystallize(radius: 10)
        map[.crystallize] = crystallize(radius: 18)

        // Halftone
        map[.dotScreen] = screen("CIDotScreen", width: 6, sharpness: 0.7)
        map[.lineScreen] = screen("CILineScreen", width: 6, sharpness: 0.7)
        map[.circularScreen] = screen("CICircularScreen", width: 6, sharpness: 0.7)

        // Edges & Sketch
        map[.edgeDetect] = edges(intensity: 4)
        map[.edgeWork] = applyFilter(named: "CIEdgeWork") { filter, _ in
            filter.setValue(2.5, forKey: kCIInputRadiusKey)
        }
        map[.comic] = applyFilter(named: "CIComicEffect")

        // Posterize
        map[.posterizeLight] = posterize(levels: 8)
        map[.posterize] = posterize(levels: 6)
        map[.posterizeHeavy] = posterize(levels: 4)
        map[.colorQuantize] = applyFilter(named: "CIColorPosterize") { filter, _ in
            filter.setValue(5, forKey: "inputLevels")
        }

        // Invert & Monochrome
        map[.invert] = applyFilter(named: "CIColorInvert")
        map[.falseColor] = applyFilter(named: "CIFalseColor") { filter, _ in
            filter.setValue(CIColor(red: 0.2, green: 0.05, blue: 0.6), forKey: "inputColor0")
            filter.setValue(CIColor(red: 1.0, green: 0.85, blue: 0.2), forKey: "inputColor1")
        }
        map[.monochromeRed] = monochrome(
            color: CIColor(red: 0.85, green: 0.2, blue: 0.15),
            intensity: 1.0
        )
        map[.monochromeBlue] = monochrome(
            color: CIColor(red: 0.15, green: 0.35, blue: 0.85),
            intensity: 1.0
        )

        map[.gloom] = applyFilter(named: "CIGloom") { filter, _ in
            filter.setValue(0.75, forKey: kCIInputIntensityKey)
            filter.setValue(12, forKey: kCIInputRadiusKey)
        }

        // Distortion
        map[.bumpDistortion] = distortion("CIBumpDistortion", radius: 180, scale: 0.55)
        map[.pinch] = distortion("CIPinchDistortion", radius: 280, scale: -0.45)
        map[.twirl] = distortion("CITwirlDistortion", radius: 280, angle: .pi / 3)
        map[.vortex] = distortion("CIVortexDistortion", radius: 280, angle: 1.8)
        map[.glassDistortion] = applyFilter(named: "CIGlassDistortion") { filter, inputImage in
            filter.setValue(10, forKey: kCIInputScaleKey)
            filter.setValue(center(inputImage), forKey: kCIInputCenterKey)
            if let noise = CIFilter(name: "CIRandomGenerator")?.outputImage?
                .cropped(to: inputImage.extent)
                .applyingFilter("CIColorMatrix", parameters: [
                    "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                    "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                    "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                    "inputAVector": CIVector(x: 0.15, y: 0.15, z: 0.15, w: 0),
                    "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                ]) {
                filter.setValue(noise, forKey: "inputTexture")
            }
        }
        map[.holeDistortion] = distortion("CIHoleDistortion", radius: 220)

        // Texture
        map[.noiseReduction] = applyFilter(named: "CINoiseReduction") { filter, _ in
            filter.setValue(0.04, forKey: "inputNoiseLevel")
            filter.setValue(0.45, forKey: "inputSharpness")
        }
        map[.speckle] = applyFilter(named: "CISpeckle") { filter, _ in
            filter.setValue(0.65, forKey: kCIInputIntensityKey)
            filter.setValue(12, forKey: kCIInputRadiusKey)
        }
        map[.pointillize] = applyFilter(named: "CIPointillize") { filter, inputImage in
            filter.setValue(18, forKey: kCIInputRadiusKey)
            filter.setValue(center(inputImage), forKey: kCIInputCenterKey)
        }
        map[.crystallizeHeavy] = crystallize(radius: 32)

        // Composite filters
        map[.vintageWarm] = compose(map, [.sepia, .warm])
        map[.vintageCool] = compose(map, [.sepiaLight, .cool])
        map[.agedFilm] = compose(map, [.fade, .sepiaLight, .vignetteSoft])
        map[.goldenHour] = compose(map, [.warmest, .bright])
        map[.arcticBlue] = compose(map, [.coolest, .saturated])
        map[.fadedColor] = compose(map, [.muted, .bright])
        map[.vividVignette] = compose(map, [.saturated, .vignetteStrong])
        map[.sketch] = compose(map, [.edgeDetect, .mono])

        return map
    }()

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

    private static func center(_ image: CIImage) -> CIVector {
        CIVector(x: image.extent.midX, y: image.extent.midY)
    }

    private static func compose(_ map: [VideoFilter: FilterApplicator], _ filters: [VideoFilter]) -> FilterApplicator {
        { inputImage in
            filters.reduce(inputImage) { image, filter in
                map[filter]?(image) ?? image
            }
        }
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

    private static func temperature(targetKelvin: CGFloat) -> FilterApplicator {
        applyFilter(named: "CITemperatureAndTint") { filter, _ in
            filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            filter.setValue(CIVector(x: targetKelvin, y: 0), forKey: "inputTargetNeutral")
        }
    }

    private static func exposure(_ ev: CGFloat) -> FilterApplicator {
        applyFilter(named: "CIExposureAdjust") { filter, _ in
            filter.setValue(ev, forKey: kCIInputEVKey)
        }
    }

    private static func highlightShadow(highlight: CGFloat, shadow: CGFloat) -> FilterApplicator {
        applyFilter(named: "CIHighlightShadowAdjust") { filter, _ in
            filter.setValue(highlight, forKey: "inputHighlightAmount")
            filter.setValue(shadow, forKey: "inputShadowAmount")
        }
    }

    private static func colorControls(
        brightness: CGFloat = 0,
        saturation: CGFloat = 1,
        contrast: CGFloat = 1
    ) -> FilterApplicator {
        applyFilter(named: "CIColorControls") { filter, _ in
            filter.setValue(brightness, forKey: kCIInputBrightnessKey)
            filter.setValue(saturation, forKey: kCIInputSaturationKey)
            filter.setValue(contrast, forKey: kCIInputContrastKey)
        }
    }

    private static func hue(_ angle: CGFloat) -> FilterApplicator {
        applyFilter(named: "CIHueAdjust") { filter, _ in
            filter.setValue(angle, forKey: kCIInputAngleKey)
        }
    }

    private static func gamma(_ power: CGFloat) -> FilterApplicator {
        applyFilter(named: "CIGammaAdjust") { filter, _ in
            filter.setValue(power, forKey: "inputPower")
        }
    }

    private static func vignette(intensity: CGFloat, radius: CGFloat) -> FilterApplicator {
        applyFilter(named: "CIVignette") { filter, _ in
            filter.setValue(intensity, forKey: kCIInputIntensityKey)
            filter.setValue(radius, forKey: kCIInputRadiusKey)
        }
    }

    private static func pixellate(scale: CGFloat) -> FilterApplicator {
        applyFilter(named: "CIPixellate") { filter, inputImage in
            filter.setValue(scale, forKey: kCIInputScaleKey)
            filter.setValue(center(inputImage), forKey: kCIInputCenterKey)
        }
    }

    private static func crystallize(radius: CGFloat) -> FilterApplicator {
        applyFilter(named: "CICrystallize") { filter, inputImage in
            filter.setValue(radius, forKey: kCIInputRadiusKey)
            filter.setValue(center(inputImage), forKey: kCIInputCenterKey)
        }
    }

    private static func screen(_ name: String, width: CGFloat, sharpness: CGFloat) -> FilterApplicator {
        applyFilter(named: name) { filter, inputImage in
            filter.setValue(width, forKey: kCIInputWidthKey)
            filter.setValue(sharpness, forKey: kCIInputSharpnessKey)
            filter.setValue(center(inputImage), forKey: kCIInputCenterKey)
        }
    }

    private static func edges(intensity: CGFloat) -> FilterApplicator {
        applyFilter(named: "CIEdges") { filter, _ in
            filter.setValue(intensity, forKey: kCIInputIntensityKey)
        }
    }

    private static func posterize(levels: CGFloat) -> FilterApplicator {
        applyFilter(named: "CIColorPosterize") { filter, _ in
            filter.setValue(levels, forKey: "inputLevels")
        }
    }

    private static func monochrome(color: CIColor, intensity: CGFloat) -> FilterApplicator {
        applyFilter(named: "CIColorMonochrome") { filter, _ in
            filter.setValue(color, forKey: kCIInputColorKey)
            filter.setValue(intensity, forKey: kCIInputIntensityKey)
        }
    }

    private static func distortion(
        _ name: String,
        radius: CGFloat,
        scale: CGFloat = 0,
        angle: CGFloat = 0
    ) -> FilterApplicator {
        applyFilter(named: name) { filter, inputImage in
            filter.setValue(radius, forKey: kCIInputRadiusKey)
            filter.setValue(center(inputImage), forKey: kCIInputCenterKey)
            if scale != 0 {
                filter.setValue(scale, forKey: kCIInputScaleKey)
            }
            if angle != 0 {
                filter.setValue(angle, forKey: kCIInputAngleKey)
            }
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

            var transform = CGAffineTransform.identity
            layerInstruction.getTransformRamp(
                for: asyncVideoCompositionRequest.compositionTime,
                start: &transform,
                end: nil,
                timeRange: nil
            )

            // Core Image uses a bottom-left origin; AVFoundation layer transforms assume top-left.
            var ciTransform = transform
            ciTransform.b *= -1
            ciTransform.c *= -1

            let rawImage = CIImage(cvPixelBuffer: sourcePixelBuffer)
            var inputImage = rawImage.transformed(by: ciTransform)

            if let filteredImage = applyFilter(to: inputImage, trackID: layerInstruction.trackID) {
                composedImage = filteredImage
            }
        }

        guard var outputImage = composedImage else {
            asyncVideoCompositionRequest.finish(with: NSError(domain: "FilterCompositor", code: -3))
            return
        }

        let preTranslateExtent = outputImage.extent.integral
        outputImage = outputImage.transformed(by: CGAffineTransform(
            translationX: -preTranslateExtent.origin.x,
            y: -preTranslateExtent.origin.y
        ))

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
