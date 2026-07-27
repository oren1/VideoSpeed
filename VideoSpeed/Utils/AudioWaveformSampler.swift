//
//  AudioWaveformSampler.swift
//  VideoSpeed
//

import AVFoundation
import CoreMedia
import Foundation

enum AudioWaveformSampler {
    private final class CacheEntry: NSObject {
        let amplitudes: [CGFloat]
        init(_ amplitudes: [CGFloat]) { self.amplitudes = amplitudes }
    }

    private static let cache = NSCache<NSURL, CacheEntry>()

    /// Single-pass waveform sampling with one `AVAssetReader`.
    /// - Parameters:
    ///   - fileURL: Audio file URL
    ///   - targetCount: Number of bars (defaults to ~4 bars/sec, capped)
    ///   - onProgress: Optional progressive updates (invoked from background; hop to MainActor in the handler)
    static func sampleAmplitudes(
        from fileURL: URL,
        targetCount: Int? = nil,
        onProgress: (@Sendable ([CGFloat]) -> Void)? = nil
    ) async -> [CGFloat] {
        if let cached = cache.object(forKey: fileURL as NSURL)?.amplitudes, !cached.isEmpty {
            return cached
        }

        let result = await Task.detached(priority: .userInitiated) {
            sampleAmplitudesSync(
                from: fileURL,
                targetCount: targetCount,
                onProgress: onProgress
            )
        }.value

        cache.setObject(CacheEntry(result), forKey: fileURL as NSURL)
        return result
    }

    private static func sampleAmplitudesSync(
        from fileURL: URL,
        targetCount: Int?,
        onProgress: (@Sendable ([CGFloat]) -> Void)?
    ) -> [CGFloat] {
        let asset = AVURLAsset(url: fileURL)
        let durationSeconds = asset.duration.seconds
        guard durationSeconds > 0,
              let track = asset.tracks(withMediaType: .audio).first else {
            return [0.15]
        }

        let count = targetCount ?? min(512, max(64, Int(ceil(durationSeconds * 4))))
        var peaks = Array(repeating: Float(0), count: count)

        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        guard let reader = try? AVAssetReader(asset: asset) else {
            return Array(repeating: 0.15, count: count)
        }

        let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        output.alwaysCopiesSampleData = false
        reader.add(output)

        guard reader.startReading() else {
            return Array(repeating: 0.15, count: count)
        }

        var buffersProcessed = 0
        let progressEvery = 24

        while reader.status == .reading {
            guard let sampleBuffer = output.copyNextSampleBuffer() else { break }

            let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
            let bucket = min(count - 1, max(0, Int((pts / durationSeconds) * Double(count))))

            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }
            let length = CMBlockBufferGetDataLength(blockBuffer)
            guard length > 1 else { continue }

            // Peek without always copying full buffer when possible.
            var dataPointer: UnsafeMutablePointer<Int8>?
            var lengthAtOffset = 0
            var totalLength = 0
            let status = CMBlockBufferGetDataPointer(
                blockBuffer,
                atOffset: 0,
                lengthAtOffsetOut: &lengthAtOffset,
                totalLengthOut: &totalLength,
                dataPointerOut: &dataPointer
            )

            if status == kCMBlockBufferNoErr, let dataPointer {
                dataPointer.withMemoryRebound(to: Int16.self, capacity: lengthAtOffset / 2) { samples in
                    let sampleCount = lengthAtOffset / 2
                    guard sampleCount > 0 else { return }
                    // Sparse stride — enough for a visible envelope, cheap to compute.
                    let strideStep = max(1, sampleCount / 16)
                    var i = 0
                    var localPeak: Float = 0
                    while i < sampleCount {
                        let value = abs(Float(samples[i]) / Float(Int16.max))
                        if value > localPeak { localPeak = value }
                        i += strideStep
                    }
                    if localPeak > peaks[bucket] {
                        peaks[bucket] = localPeak
                    }
                }
            } else {
                var data = Data(count: length)
                data.withUnsafeMutableBytes { rawBuffer in
                    guard let base = rawBuffer.baseAddress else { return }
                    CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: base)
                }
                data.withUnsafeBytes { rawBuffer in
                    let samples = rawBuffer.bindMemory(to: Int16.self)
                    guard !samples.isEmpty else { return }
                    let strideStep = max(1, samples.count / 16)
                    var i = 0
                    var localPeak: Float = 0
                    while i < samples.count {
                        let value = abs(Float(samples[i]) / Float(Int16.max))
                        if value > localPeak { localPeak = value }
                        i += strideStep
                    }
                    if localPeak > peaks[bucket] {
                        peaks[bucket] = localPeak
                    }
                }
            }

            buffersProcessed += 1
            if let onProgress, buffersProcessed % progressEvery == 0 {
                onProgress(normalize(peaks))
            }
        }

        let normalized = normalize(peaks)
        onProgress?(normalized)
        return normalized
    }

    private static func normalize(_ peaks: [Float]) -> [CGFloat] {
        let maxPeak = peaks.max() ?? 0
        guard maxPeak > 0 else {
            return peaks.map { _ in CGFloat(0.12) }
        }
        return peaks.map { value in
            CGFloat(max(0.08, min(1, value / maxPeak)))
        }
    }
}
