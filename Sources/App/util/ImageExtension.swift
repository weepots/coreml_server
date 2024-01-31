//
//  SwiftUIView.swift
//  
//
//  Created by hansoong choong on 8/4/22.
//

import CoreImage
import AppKit
import AVFoundation
//import CoreMLHelper

extension NSImage {
    func pngData(
        size: CGSize,
        imageInterpolation: NSImageInterpolation = .high
    ) -> Data? {
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [],
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }
        
        bitmap.size = size
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.current?.imageInterpolation = imageInterpolation
        draw(
            in: NSRect(origin: .zero, size: size),
            from: .zero,
            operation: .copy,
            fraction: 1.0
        )
        NSGraphicsContext.restoreGraphicsState()
        
        return bitmap.representation(using: .png, properties: [:])
    }
}

extension CIImage {
    func convertCIImageToCGImage() -> CGImage {
        let context = CIContext(options: nil)
        return context.createCGImage(self, from: self.extent)!
    }
    
    @objc func saveJPEG(_ name:String, inDirectoryURL:URL? = nil, quality:CGFloat = 1.0) -> String? {
        
        var destinationURL = inDirectoryURL
        
        if destinationURL == nil {
            destinationURL = try? FileManager.default.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        }
        
        if var destinationURL = destinationURL {
            
            destinationURL = destinationURL.appendingPathComponent(name)
            
            if let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) {
                
                do {
                    
                    let context = CIContext()
                    
                    try context.writeJPEGRepresentation(of: self, to: destinationURL, colorSpace: colorSpace, options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption : quality])
                    
                    return destinationURL.path
                    
                } catch {
                    return nil
                }
            }
        }
        
        return nil
    }
                
    func getOrientation() -> Int32 {
       let pros = self.properties
       
       if let orientation = pros["Orientation"] {
           return (orientation as? Int32) ?? 1
       }
       return 1
    }
    
}

//extension CVPixelBuffer {
//    func maxSize(length: Int) -> CVPixelBuffer {
//        let (scaleWidth, scaleHeight) = getProcessSize(maxLength: length)
//        
//        if scaleWidth > 0 {
//            return resizePixelBuffer(self, width: scaleWidth, height: scaleHeight)!
//        }
//        return self
//    }
//    
//    func getProcessSize(maxLength: Int) -> (Int, Int) {
//        let width = CVPixelBufferGetWidth(self)
//        let height = CVPixelBufferGetHeight(self)
//
//        if width > height {
//            if width > maxLength {
//                return (maxLength, Int(maxLength * height / width))
//            }
//        } else {
//            if height > maxLength {
//                return (Int(maxLength * width / height), maxLength)
//            }
//        }
//        
//        return (-1, -1)
//    }
//}
