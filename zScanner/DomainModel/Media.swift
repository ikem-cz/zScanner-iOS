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
            return makeVideoThumbnail()
        }
    }
    
    init(type: MediaType, correlationId: String, fromGallery: Bool) {
        self.id = UUID().uuidString
        self.type = type
        self.correlationId = correlationId
        self.relativePath = correlationId + "/" + id + type.suffix
        self.fromGallery = fromGallery
    }
    
    func makeVideoThumbnail() -> UIImage? {
        let asset = AVURLAsset(url: url)
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
        let top = observation.points.sorted(by: { $0.y < $1.y }).prefix(2)
        let bottom = observation.points.sorted(by: { $0.y > $1.y }).prefix(2)
        
        let topLeft = top.sorted(by: { $0.x < $1.x }).first!
        let topRight = top.sorted(by: { $0.x < $1.x }).last!
        let bottomLeft = bottom.sorted(by: { $0.x < $1.x }).first!
        let bottomRight = bottom.sorted(by: { $0.x < $1.x }).last!
        
        // convert corners from normalized image coordinates to pixel coordinates
        let scaledTopLeft = topLeft.scaled(to: ciImage.extent.size)
        let scaledTopRight = topRight.scaled(to: ciImage.extent.size)
        let scaledBottomLeft = bottomLeft.scaled(to: ciImage.extent.size)
        let scaledBottomRight = bottomRight.scaled(to: ciImage.extent.size)

        // pass those to the filter to extract/rectify the image
        return ciImage.applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: scaledTopLeft),
            "inputTopRight": CIVector(cgPoint: scaledTopRight),
            "inputBottomLeft": CIVector(cgPoint: scaledBottomLeft),
            "inputBottomRight": CIVector(cgPoint: scaledBottomRight),
        ])
    }
}

private extension CGPoint {
   func scaled(to size: CGSize) -> CGPoint {
       return CGPoint(x: self.x * size.width,
                      y: self.y * size.height)
   }
}
