//
//  File.swift
//
//
//  Created by Alexander Ng on 26/1/24.
//

import Foundation
import Fluent
import Vapor
import CoreML
import CoreGraphics
import UniformTypeIdentifiers
import Cocoa
import CoreImage
import NaturalLanguage


//@available(iOS 16.2, macOS 13.1, *)
struct StableDiffusionController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let sdRoutes = routes.grouped("stableDiffuse")
        sdRoutes.post(use:generateImage)
    }
    
    func generateImage(req:Request) throws -> EventLoopFuture<Response> {
        
        let stableDiffusionRequest = try req.content.decode(StableDiffusionRequest.self)
    
        let prompt = stableDiffusionRequest.prompt
        
        let resourcePath = "Sources/App/StableDiffusion/model-1-5"
        
        guard FileManager.default.fileExists(atPath: resourcePath) else {
            throw RunError.resources("Resource path does not exist \(resourcePath)")
        }
        guard #available(iOS 16.2, macOS 13.1, * )else {
            let oldOsResponse = Response(status: .internalServerError)
            return req.eventLoop.future(oldOsResponse)
        }
        
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndGPU
        let resourceURL = URL(filePath: resourcePath)
        let pipeline: StableDiffusionPipelineProtocol
        var seed = 93
        var imageCount = 1
        var outputPath: String = "./"
        var scaleFactor: Float32 = 0.1825
        var controlnet: [String] = []
        var disableSafety: Bool = false
        var reduceMemory: Bool = true
        var useMultilingualTextEncoder: Bool = false
        var script: Script = .latin
        
        if #available(macOS 14.0, iOS 17.0, *) {
            pipeline = try StableDiffusionPipeline(
                resourcesAt: resourceURL,
                controlNet: controlnet,
                configuration: config,
                disableSafety: disableSafety,
                reduceMemory: reduceMemory,
                useMultilingualTextEncoder: useMultilingualTextEncoder,
                script: script
            )
        } else {
            pipeline = try StableDiffusionPipeline(
                resourcesAt: resourceURL,
                controlNet: controlnet,
                configuration: config,
                disableSafety: disableSafety,
                reduceMemory: reduceMemory
            )
        }
        
        let sampleTimer = SampleTimer()
        sampleTimer.start()
        print("Loading resources...")
        try pipeline.loadResources()
        
        var pipelineConfig = StableDiffusionPipeline.Configuration(prompt: prompt)
        
//        pipelineConfig.negativePrompt = negativePrompt
//        pipelineConfig.startingImage = startingImage
//        pipelineConfig.strength = strength
        pipelineConfig.imageCount = imageCount
        pipelineConfig.stepCount = 50
        pipelineConfig.seed = UInt32(seed)
//        pipelineConfig.controlNetInputs = controlNetInputs
        pipelineConfig.guidanceScale = 7.5
//        pipelineConfig.schedulerType = scheduler.stableDiffusionScheduler
//        pipelineConfig.rngType = rng.stableDiffusionRNG
        pipelineConfig.useDenoisedIntermediates = true
        pipelineConfig.encoderScaleFactor = scaleFactor
        pipelineConfig.decoderScaleFactor = scaleFactor
        
        print("Starting generation")
        
        let images = try pipeline.generateImages(
            configuration: pipelineConfig) { progress in
                sampleTimer.stop()
                handleProgress(progress,sampleTimer)
                if progress.stepCount != progress.step {
                    sampleTimer.start()
                }
                return true
            }
        let cgImage = images[0]
        
//        _ = try saveImages(images, logNames: true)
        let pngImage =  convertCGImageToPNGData(cgImage: cgImage!)
        let response = Response(status: .ok, body: .init(data: pngImage!))
                response.headers.contentType = .png
        
        
        
        return req.eventLoop.future(response)
        
    }
    func log(_ str: String, term: String = "") {
        print(str, terminator: term)
    }
    @available(macOS 13.1, *)
    func handleProgress(
        _ progress: StableDiffusionPipeline.Progress,
        _ sampleTimer: SampleTimer
    ) {
        log("\u{1B}[1A\u{1B}[K")
        log("Step \(progress.step) of \(progress.stepCount) ")
        log(" [")
        log(String(format: "mean: %.2f, ", 1.0/sampleTimer.mean))
        log(String(format: "median: %.2f, ", 1.0/sampleTimer.median))
        log(String(format: "last %.2f", 1.0/sampleTimer.allSamples.last!))
        log("] step/sec")
        log("\n")
    }
    
//    func convertCGImageToJPEGData(cgImage: CGImage) -> Data? {
//        guard let destinationData = NSMutableData() as CFMutableData?,
//              let destination = CGImageDestinationCreateWithData(destinationData as CFMutableData, kUTTypePNG, 1, nil) else {
//            // Handle the case when creating CGImageDestination fails
//            return nil
//        }
//
//        // Add the CGImage to the destination with compression quality
//        let properties: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 1.0]
//        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
//
//        // Finalize the destination to produce the JPEG data
//        guard CGImageDestinationFinalize(destination) else {
//            // Handle the case when finalizing the destination fails
//            return nil
//        }
//
//        return destinationData as Data
//    }
    
//    func saveImages(
//        _ images: [CGImage?],
//        step: Int? = nil,
//        logNames: Bool = false
//    ) throws -> Int {
//        let url = URL(filePath: outputPath)
//        var saved = 0
//        for i in 0 ..< images.count {
//
//            guard let image = images[i] else {
//                if logNames {
//                    log("Image \(i) failed safety check and was not saved")
//                }
//                continue
//            }
//
//            let name = imageName(i, step: step)
//            let fileURL = url.appending(path:name)
//
//            guard let dest = CGImageDestinationCreateWithURL(fileURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
//                throw RunError.saving("Failed to create destination for \(fileURL)")
//            }
//            CGImageDestinationAddImage(dest, image, nil)
//            if !CGImageDestinationFinalize(dest) {
//                throw RunError.saving("Failed to save \(fileURL)")
//            }
//            if logNames {
//                log("Saved \(name)\n")
//            }
//            saved += 1
//        }
//        return saved
//    }

//    func imageName(_ sample: Int, step: Int? = nil) -> String {
//        let fileCharLimit = 75
//        var name = prompt.prefix(fileCharLimit).replacingOccurrences(of: " ", with: "_")
//        if imageCount != 1 {
//            name += ".\(sample)"
//        }
//
//        if image != nil {
//            name += ".str\(Int(strength * 100))"
//        }
//
//        name += ".\(seed)"
//
//        if let step = step {
//            name += ".\(step)"
//        } else {
//            name += ".final"
//        }
//        name += ".png"
//        return name
//    }
    
}
enum RunError: Error {
    case resources(String)
    case saving(String)
    case unsupported(String)
}

