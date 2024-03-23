//
//  File.swift
//
//
//  Created by Alexander Ng on 23/1/24.
//

import Fluent
import Vapor
import Vision
import CoreML
import CoreImage


struct SuperResolutionController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.on(.POST,
                  "superRes",
                  body: .collect(maxSize: ByteCount(value: 20000*1024)),
                  use: superresolution
        )
    }

    func superresolution(req: Request) throws -> EventLoopFuture<Response> {
        let superResRequest = try req.content.decode(SuperResRequest.self)
        let base64Image = superResRequest.image
        let configuration = MLModelConfiguration()
        let data = Data(base64Encoded: base64Image)
        let testCIImage = CIImage(data : data!)!
        let cgImage = testCIImage.convertCIImageToCGImage()
        let pixelbufferRaw = cgImage.pixelBuffer()
        let pixelbuffer = resizePixelBuffer(pixelbufferRaw!, width:512, height:512)
        var response = Response()

        if let output = try? realesrgan512(configuration: configuration).prediction(input:pixelbuffer!).activation_out{
            let ciImage = CIImage(cvImageBuffer:output)
            let context = CIContext()

            let imageData = try ciImageToPNGData(ciImage: ciImage)
            let images: [Data] = [imageData]
            let base64Images = images.map { $0.base64EncodedString() }
            
            let json = try JSONSerialization.data(withJSONObject: base64Images, options: [])
            let response = Response(status: .ok, body: .init(data:json))
            response.headers.replaceOrAdd(name: .contentType, value: "application/json")
            return req.eventLoop.future(response)

        }
        return req.eventLoop.future(response)
        
    }
    
    func write(cgimage: CGImage, to url: URL) throws {
        let cicontext = CIContext()
        let ciimage = CIImage(cgImage: cgimage)
        try cicontext.writePNGRepresentation(of: ciimage, to: url, format: .RGBA8, colorSpace: ciimage.colorSpace!)
    }
    
    func convertCGImageToBase64(cgImage: CGImage) -> String? {
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(data: nil,
                                width: cgImage.width,
                                height: cgImage.height,
                                bitsPerComponent: cgImage.bitsPerComponent,
                                bytesPerRow: 0,
                                space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: bitmapInfo.rawValue)

        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(cgImage.width), height: CGFloat(cgImage.height)))

        guard let outputData = context?.makeImage()?.dataProvider?.data as Data? else {
            return nil
        }

        let base64String = outputData.base64EncodedString()
        print(base64String.prefix(5))
        return base64String
    }
    
//    func ciImageToJPEGData(ciImage: CIImage, compressionQuality: CGFloat = 0.8) throws -> Data {
//        let context = CIContext()
//        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
//            throw Abort(.internalServerError, reason: "Failed to create CGImage from CIImage")
//        }
//
//        let options: NSDictionary = [
//            kCGImageDestinationLossyCompressionQuality: compressionQuality as NSNumber
//        ]
//
//        let imageData = NSMutableData()
//        guard let destination = CGImageDestinationCreateWithData(imageData, kUTTypeJPEG, 1, nil) else {
//            throw Abort(.internalServerError, reason: "Failed to create CGImageDestination")
//        }
//
//        CGImageDestinationAddImage(destination, cgImage, options)
//        guard CGImageDestinationFinalize(destination) else {
//            throw Abort(.internalServerError, reason: "Failed to finalize CGImageDestination")
//        }
//
//        return imageData as Data
//    }

    
   
}

