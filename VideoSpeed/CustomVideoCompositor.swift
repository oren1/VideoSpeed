//
//  MyCustomCompositor.swift
//  VideoSpeed
//
//  Created by oren shalev on 17/11/2024.
//

import AVFoundation
import CoreImage

class CustomVideoCompositor: NSObject, AVVideoCompositing {
    let renderContextQueue = DispatchQueue(label: "com.example.renderContextQueue")
    var renderContext: AVVideoCompositionRenderContext?
    
    var sourcePixelBufferAttributes: [String : any Sendable]? = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
//        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange
    ]
    
    var requiredPixelBufferAttributesForRenderContext: [String : any Sendable] =  [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
//        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange
    ]
    
//    var supportsHDRSourceFrames: Bool = true
    
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderContextQueue.sync {
                   renderContext = newRenderContext
        }
    }
    
    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        guard let pixelBuffer = asyncVideoCompositionRequest.sourceFrame(byTrackID: 1) else {
                   asyncVideoCompositionRequest.finish(with: NSError(domain: "CustomVideoCompositor", code: -1, userInfo: nil))
                   return
               }

               // Apply filter to the pixel buffer
               let filteredBuffer = applyFilter(to: pixelBuffer)

               asyncVideoCompositionRequest.finish(withComposedVideoFrame: filteredBuffer)
    }
    
    
    private func applyFilter(to pixelBuffer: CVPixelBuffer) -> CVPixelBuffer {
        // Convert CVPixelBuffer to CIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Apply a Core Image filter
        let filter = CIFilter(name: "CISepiaTone")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(0.8, forKey: kCIInputIntensityKey)

        guard let outputImage = filter.outputImage else {
            return pixelBuffer
        }

        // Render the filtered image to a new CVPixelBuffer
        let context = CIContext()
        let outputPixelBuffer = createPixelBuffer(from: pixelBuffer)

        context.render(outputImage, to: outputPixelBuffer!)

        return outputPixelBuffer!
    }
    
    private func createPixelBuffer(from pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
           var newPixelBuffer: CVPixelBuffer?
           CVPixelBufferCreate(kCFAllocatorDefault,
                               CVPixelBufferGetWidth(pixelBuffer),
                               CVPixelBufferGetHeight(pixelBuffer),
                               CVPixelBufferGetPixelFormatType(pixelBuffer),
                               nil,
                               &newPixelBuffer)
           return newPixelBuffer
       }
}
