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
    
    func save() {}
}

extension Media: Equatable {
    static func == (lhs: Media, rhs: Media) -> Bool {
        return lhs.id == rhs.id
    }
}

class ScanMedia: Media {
    var cropRelativePath: String!
    var cropUrl: URL { URL(documentsWith: cropRelativePath) }
    
    var rectangle: VNRectangleObservation
    
    init(scanRectangle: VNRectangleObservation, correlationId: String, fromGallery: Bool) {
        self.rectangle = scanRectangle
        super.init(type: .scan, correlationId: correlationId, fromGallery: fromGallery)

        self.cropRelativePath = correlationId + "/" + id + "-crop" + type.suffix
    }
    
    override func save() {
        super.save()
        
        guard let cropData = thumbnail?.jpegData(compressionQuality: 0.8) else { return }
        do {
            try cropData.write(to: cropUrl)
        } catch let error {
            print("error saving image crop with error", error)
        }
    }
    
    override var thumbnail: UIImage? {
        guard
            let ciImage = CIImage(contentsOf: url),
            let uiImage = UIImage(data: try! Data(contentsOf: url))
        else { return nil }
        let orientation = CGImagePropertyOrientation(uiOrientation: uiImage.imageOrientation)
        
        let page = extractPerspectiveRect(rectangle, from: ciImage.oriented(orientation))
        return UIImage(ciImage: page)
    }
    
    func extractPerspectiveRect(_ observation: VNRectangleObservation, from ciImage: CIImage) -> CIImage {
        let scaledTopLeft = observation.topLeft.scaled(to: ciImage.extent.size)
        let scaledTopRight = observation.topRight.scaled(to: ciImage.extent.size)
        let scaledBottomLeft = observation.bottomLeft.scaled(to: ciImage.extent.size)
        let scaledBottomRight = observation.bottomRight.scaled(to: ciImage.extent.size)

        // pass those to the filter to extract/rectify the image
        return ciImage
            .applyingFilter("CIPerspectiveCorrection", parameters: [
            "inputTopLeft": CIVector(cgPoint: scaledTopLeft),
            "inputTopRight": CIVector(cgPoint: scaledTopRight),
            "inputBottomLeft": CIVector(cgPoint: scaledBottomLeft),
            "inputBottomRight": CIVector(cgPoint: scaledBottomRight),
        ])
    }
}

private extension CGPoint {
   func scaled(to size: CGSize) -> CGPoint {
       return CGPoint(x: x * size.width, y: y * size.height)
   }
}
