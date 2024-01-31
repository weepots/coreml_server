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
                  body: .collect(maxSize: ByteCount(value: 2000*1024)),
                  use: superresolution
        )
    }

    func superresolution(req: Request) throws -> EventLoopFuture<Response> {
        
        let superResRequest = try req.content.decode(SuperResRequest.self)
        let base64Image = superResRequest.image
        let configuration = MLModelConfiguration()
//        let url = URL(fileURLWithPath: "/Users/alexander/Downloads/Lab7.jpg")
//        let _ = print("url = \(url)")
        let data = try! Data(base64Encoded: base64Image)
        let testCIImage = CIImage(data : data!)!
        let cgImage = testCIImage.convertCIImageToCGImage()
        let pixelbuffer = cgImage.pixelBuffer()
        var response = Response()
//        var imageResponse = SuperResResponse(image:"")
        if let output = try? realesrgan512(configuration: configuration).prediction(input:pixelbuffer!).activation_out{
            print(output)
            let ciImage = CIImage(cvImageBuffer:output)
            let context = CIContext()
            
//            let cgOutputImage = context.createCGImage(ciImage, from: ciImage.extent)
//            try? write(cgimage: cgOutputImage!, to: URL(fileURLWithPath: "/Users/alexander/Documents/fyp/macosai/coreml_server/output.jpg"))

            let imageData = try ciImageToJPEGData(ciImage: ciImage)
            // Create a Vapor Response with the image data
            response = Response(status: .ok, body: .init(data: imageData))
                    response.headers.contentType = .jpeg


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
    
    func ciImageToJPEGData(ciImage: CIImage, compressionQuality: CGFloat = 0.8) throws -> Data {
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw Abort(.internalServerError, reason: "Failed to create CGImage from CIImage")
        }

        let options: NSDictionary = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality as NSNumber
        ]

        let imageData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(imageData, kUTTypeJPEG, 1, nil) else {
            throw Abort(.internalServerError, reason: "Failed to create CGImageDestination")
        }

        CGImageDestinationAddImage(destination, cgImage, options)
        guard CGImageDestinationFinalize(destination) else {
            throw Abort(.internalServerError, reason: "Failed to finalize CGImageDestination")
        }

        return imageData as Data
    }

    
   
}

