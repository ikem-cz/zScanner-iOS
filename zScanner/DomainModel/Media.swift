//
//  Media.swift
//  zScanner
//
//  Created by Jan Provazník on 18/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class Media {
    let id: String
    let type: MediaType
    let correlationId: String
    let relativePath: String
    let fromGallery: Bool
    var url: URL { URL(documentsWith: relativePath) }
    
    var thumbnail: UIImage? {
        switch type {
        case .photo, .scan:
            return UIImage(data: try! Data(contentsOf: url))!
        case .video:
            return videoThumbnail
        }
    }
    
    var videoThumbnail: UIImage? {
        let asset = AVURLAsset(url: self.url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        let timestamp = CMTime(seconds: 1, preferredTimescale: 60)

        do {
            let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch let error as NSError {
            print("Video snapshot generation failed with error \(error)")
            return nil
        }
    }
    
    init(type: MediaType, correlationId: String, fromGallery: Bool) {
        self.id = UUID().uuidString
        self.type = type
        self.correlationId = correlationId
        self.relativePath = correlationId + "/" + id + type.suffix
        self.fromGallery = fromGallery
    }
}

extension Media: Equatable {
    static func == (lhs: Media, rhs: Media) -> Bool {
        return lhs.id == rhs.id
    }
}

class ScanMedia: Media {
    var rectangle: VNRectangleObservation
    
    init(scanRectangle: VNRectangleObservation, correlationId: String, fromGallery: Bool) {
        self.rectangle = scanRectangle
        super.init(type: .scan, correlationId: correlationId, fromGallery: fromGallery)
    }
    
    override var thumbnail: UIImage? {
        guard let ciImage = CIImage(contentsOf: url) else { return nil }
        
        let page = extractPerspectiveRect(rectangle, from: ciImage)
        return UIImage(ciImage: page)
    }
    
    func extractPerspectiveRect(_ observation: VNRectangleObservation, from ciImage: CIImage) -> CIImage {
        // convert corners from normalized image coordinates to pixel coordinates
        let topLeft = observation.topLeft.scaled(to: ciImage.extent.size)
        let topRight = observation.topRight.scaled(to: ciImage.extent.size)
        let bottomLeft = observation.bottomLeft.scaled(to: ciImage.extent.size)
        let bottomRight = observation.bottomRight.scaled(to: ciImage.extent.size)

        // pass those to the filter to extract/rectify the image
        return ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: topLeft),
            "inputTopRight": CIVector(cgPoint: topRight),
            "inputBottomLeft": CIVector(cgPoint: bottomLeft),
            "inputBottomRight": CIVector(cgPoint: bottomRight),
        ])
    }
}

private extension CGPoint {
   func scaled(to size: CGSize) -> CGPoint {
       return CGPoint(x: self.x * size.width,
                      y: self.y * size.height)
   }
}
