//
//  File.swift
//  
//
//  Created by Alexander Ng on 7/2/24.
//

import Foundation
import Vapor
import Fluent
import CoreML
import CoreImage

struct BackgroundRemoverController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.on(.POST,
                  "backgroundRemove",
                  body: .collect(maxSize: ByteCount(value: 2000*1024)),
                  use: removeBackground
        )
    }
    func removeBackground (req:Request)throws ->EventLoopFuture<Response> {
        let backgroundRemoveRequest = try req.content.decode(backgroundRemoveRequest.self)
        let base64Image = backgroundRemoveRequest.image
        let configuration = MLModelConfiguration()
//        let url = URL(fileURLWithPath: "/Users/alexander/Downloads/lena_std.jpg")
//        let _ = print("url = \(url)")
//        let data = try! Data(contentsOf: url)
        let data = Data(base64Encoded: base64Image)
        let testCIImage = CIImage(data : data!)!
        let cgImage = testCIImage.convertCIImageToCGImage()
        let pixelbufferRaw = cgImage.pixelBuffer()
        let ogHeight = CVPixelBufferGetHeight(pixelbufferRaw!)
        let ogWidth = CVPixelBufferGetWidth(pixelbufferRaw!)
        print(ogHeight, ogWidth)
        let pixelbuffer = resizePixelBuffer(pixelbufferRaw!, width:320, height:320)
        let segmented = try? u2net(configuration: configuration).prediction(input:pixelbuffer!).out_p1
        let segmentedCI = CIImage(cvImageBuffer:segmented!)
        let segmentedUpscale = try ciimageUpscale(sourceImage: segmentedCI, targetHeight:ogHeight, targetWidth: ogWidth)
//        let resizeFilter = CIFilter(name:"CILanczosScaleTransform")!
//        let targetSize = NSSize(width:ogWidth, height:ogHeight)
//        let scale = targetSize.height / (segmentedCI.extent.height)
//        let aspectRatio = targetSize.width/((segmentedCI.extent.width) * scale)
//
//        // Apply resizing
//        resizeFilter.setValue(segmentedCI, forKey: kCIInputImageKey)
//        resizeFilter.setValue(scale, forKey: kCIInputScaleKey)
//        resizeFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
//        let outputImage = resizeFilter.outputImage
        
//        let segmentedUpscale = resizePixelBuffer(segmented!, width:ogWidth, height:ogHeight)
//        let ciSegmented = CIImage(cvImageBuffer: segmentedUpscale!).applyingGaussianBlur(sigma: 3)
        let ciSegmented = segmentedUpscale.applyingGaussianBlur(sigma: 3)
        let compositeFilter = CIFilter(name: "CIBlendWithMask")!
        compositeFilter.setValue(testCIImage, forKey: kCIInputImageKey)
        compositeFilter.setValue(ciSegmented, forKey: kCIInputMaskImageKey)
        compositeFilter.setValue(CIImage.empty(), forKey: kCIInputBackgroundImageKey)
        let compositeImage = compositeFilter.outputImage
        let context = CIContext()
        ///construct sr image
        let cgOutputImage =  context.createCGImage(compositeImage!, from:compositeImage!.extent)
        let pngImage =  convertCGImageToPNGData(cgImage: cgOutputImage!)
        let response = Response(status: .ok, body: .init(data: pngImage!))
                response.headers.contentType = .png
        
//        let temp = CIImage(cvImageBuffer: segmentedUpscale!)
//        let cgSaveImage = context.createCGImage(outputImage!, from:outputImage!.extent)
//        try? write(cgimage: cgSaveImage!, to: URL(fileURLWithPath: "output.png"))
        
        return req.eventLoop.future(response)
    
    }
    func write(cgimage: CGImage, to url: URL) throws {
        let cicontext = CIContext()
        let ciimage = CIImage(cgImage: cgimage)
        try cicontext.writePNGRepresentation(of: ciimage, to: url, format: .RGBA8, colorSpace: ciimage.colorSpace!)
    }
    func ciimageUpscale (sourceImage: CIImage,targetHeight: Int, targetWidth: Int) throws -> CIImage{
        
        let resizeFilter = CIFilter(name:"CILanczosScaleTransform")!
        let targetSize = NSSize(width:targetWidth, height:targetHeight)
        let scale = targetSize.height / (sourceImage.extent.height)
        let aspectRatio = targetSize.width/((sourceImage.extent.width) * scale)

        // Apply resizing
        resizeFilter.setValue(sourceImage, forKey: kCIInputImageKey)
        resizeFilter.setValue(scale, forKey: kCIInputScaleKey)
        resizeFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
        let outputImage = resizeFilter.outputImage
        return outputImage!
    }
}
    
