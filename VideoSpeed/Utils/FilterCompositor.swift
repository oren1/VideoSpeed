//
//  FilterCompositor.swift
//  VideoSpeed
//

import AVFoundation
import CoreImage

enum VideoFilter {
    case none
    case sepia

    /// Hardcoded active filter — change to `.none` to disable.
    static var current: VideoFilter = .sepia

    var usesCustomCompositor: Bool {
        self != .none
    }
}

class FilterCompositor: NSObject, AVVideoCompositing {

    static var activeFilter: VideoFilter = VideoFilter.current

    var sourcePixelBufferAttributes: [String: Any]? = [
        kCVPixelBufferPixelFormatTypeKey as String: [kCVPixelFormatType_32BGRA]
    ]

    var requiredPixelBufferAttributesForRenderContext: [String: Any] = [
        kCVPixelBufferPixelFormatTypeKey as String: [kCVPixelFormatType_32BGRA]
    ]

    private let ciContext = CIContext()

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
//            guard let layerInstruction = layerInstruction as? AVVideoCompositionLayerInstruction else { continue }

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

            if let filteredImage = applyFilter(to: inputImage) {
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

    private func applyFilter(to inputImage: CIImage) -> CIImage? {
        switch Self.activeFilter {
        case .none:
            return inputImage
        case .sepia:
            guard let filter = CIFilter(name: "CISepiaTone") else { return inputImage }
            filter.setValue(inputImage, forKey: kCIInputImageKey)
            filter.setValue(0.8, forKey: kCIInputIntensityKey)
            return filter.outputImage ?? inputImage
        }
    }
}
