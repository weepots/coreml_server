//
//  File.swift
//  
//
//  Created by Alexander Ng on 7/2/24.
//

import Foundation
import CoreImage
import Foundation
import Fluent
import Vapor
import AVFoundation

func ciImageToPNGData(ciImage: CIImage, compressionQuality: CGFloat = 0.8) throws -> Data {
    let context = CIContext()
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
        throw Abort(.internalServerError, reason: "Failed to create CGImage from CIImage")
    }

    let options: NSDictionary = [
        kCGImageDestinationLossyCompressionQuality: compressionQuality as NSNumber
    ]

    let imageData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(imageData, "public.png" as CFString, 1, nil) else {
        throw Abort(.internalServerError, reason: "Failed to create CGImageDestination")
    }

    CGImageDestinationAddImage(destination, cgImage, options)
    guard CGImageDestinationFinalize(destination) else {
        throw Abort(.internalServerError, reason: "Failed to finalize CGImageDestination")
    }

    return imageData as Data
}

func convertCGImageToPNGData(cgImage: CGImage) -> Data? {
    guard let destinationData = NSMutableData() as CFMutableData?,
          let destination = CGImageDestinationCreateWithData(destinationData as CFMutableData, "public.png" as CFString, 1, nil) else {
        // Handle the case when creating CGImageDestination fails
        return nil
    }

    // Add the CGImage to the destination with compression quality
    let properties: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 1.0]
    CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)

    // Finalize the destination to produce the JPEG data
    guard CGImageDestinationFinalize(destination) else {
        // Handle the case when finalizing the destination fails
        return nil
    }

    return destinationData as Data
}

