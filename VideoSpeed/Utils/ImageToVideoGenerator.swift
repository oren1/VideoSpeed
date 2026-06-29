//
//  ImageToVideoGenerator.swift
//  VideoSpeed
//

import AVFoundation
import UIKit

enum ImageToVideoGenerator {
    static let maxDurationSeconds: Double = 60
    static let defaultDurationSeconds: Double = 5
    static let minDurationSeconds: Double = 3
    static let fps: Int32 = 30

    enum Error: Swift.Error {
        case missingCGImage
        case writerSetupFailed
        case pixelBufferCreationFailed
        case writingFailed
    }

    /// Creates a minimal 1-frame video asset. Display duration is applied later via composition scaling.
    static func makeVideo(from image: UIImage) async throws -> AVURLAsset {
        let normalized = image.normalized()
        guard var cgImage = normalized.cgImage else {
            throw Error.missingCGImage
        }

        var width = cgImage.width
        var height = cgImage.height
        if width % 2 != 0 { width -= 1 }
        if height % 2 != 0 { height -= 1 }
        if width != cgImage.width || height != cgImage.height {
            cgImage = cgImage.cropping(to: CGRect(x: 0, y: 0, width: width, height: height)) ?? cgImage
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height
            ]
        )

        guard writer.canAdd(input) else { throw Error.writerSetupFailed }
        writer.add(input)
        guard writer.startWriting() else { throw Error.writerSetupFailed }
        writer.startSession(atSourceTime: .zero)

        guard let pixelBuffer = makePixelBuffer(from: cgImage, width: width, height: height) else {
            throw Error.pixelBufferCreationFailed
        }

        while !input.isReadyForMoreMediaData {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        guard adaptor.append(pixelBuffer, withPresentationTime: .zero) else {
            throw Error.writingFailed
        }

        input.markAsFinished()
        await writer.finishWriting()
        guard writer.status == .completed else { throw Error.writingFailed }

        return AVURLAsset(url: outputURL)
    }

    private static func makePixelBuffer(from cgImage: CGImage, width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attributes,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buffer
    }
}

private extension UIImage {
    func normalized() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
