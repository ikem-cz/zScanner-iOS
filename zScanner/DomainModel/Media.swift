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
    var index: Int?
    let type: MediaType
    let correlationId: String
    let relativePath: String
    var cropRelativePath: String
    let fromGallery: Bool
    var desription: String?
    var cropRectangle: VNRectangleObservation?
    var url: URL { URL(documentsWith: relativePath) }
    var cropUrl: URL? { cropRectangle == nil ? nil : URL(documentsWith: cropRelativePath) }
    
    #warning("TODO: Save defect and description to database")
    var defect: BodyDefectDomainModel?
    
    var thumbnail: UIImage? {
        switch type {
        case .photo, .scan:
            guard let uiImage = UIImage(data: try! Data(contentsOf: url)) else { return nil }
            guard
                let rectangle = cropRectangle,
                let ciImage = CIImage(contentsOf: url)
            else {
                return uiImage
            }
            let orientation = CGImagePropertyOrientation(uiOrientation: uiImage.imageOrientation)
            
            let page = extractPerspectiveRect(rectangle, from: ciImage.oriented(orientation))
            return UIImage(ciImage: page)

        case .video:
            return makeVideoThumbnail()
        }
    }
    
    init(type: MediaType, correlationId: String, fromGallery: Bool) {
        self.id = UUID().uuidString
        self.type = type
        self.correlationId = correlationId
        self.relativePath = correlationId + "/" + id + type.suffix
        self.cropRelativePath = correlationId + "/" + id + "-crop" + type.suffix
        self.fromGallery = fromGallery
    }
    
    convenience init(scanRectangle: VNRectangleObservation, correlationId: String, fromGallery: Bool) {
        self.init(type: .scan, correlationId: correlationId, fromGallery: fromGallery)

        self.cropRectangle = scanRectangle
    }
    
    init(id: String, index: Int?, type: MediaType, correlationId: String, relativePath: String, cropRelativePath: String) {
        self.id = id
        self.index = index
        self.type = type
        self.correlationId = correlationId
        self.relativePath = relativePath
        self.cropRelativePath = cropRelativePath
        self.fromGallery = false
    }
    
    func saveCrop() {
        guard let cropUrl = cropUrl, let cropData = thumbnail?.jpegData(compressionQuality: 0.8) else { return }
        do {
            try cropData.write(to: cropUrl)
        } catch let error {
            print("error saving image crop with error", error)
        }
    }
    
    func deleteMedia() {
        try? FileManager.default.removeItem(at: url)
        cropUrl.flatMap { try? FileManager.default.removeItem(at: $0) }
    }
    
    private func makeVideoThumbnail() -> UIImage? {
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
    
    private func extractPerspectiveRect(_ observation: VNRectangleObservation, from ciImage: CIImage) -> CIImage {
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

extension Media: Equatable {
    static func == (lhs: Media, rhs: Media) -> Bool {
        return lhs.id == rhs.id
    }
}

private extension CGPoint {
   func scaled(to size: CGSize) -> CGPoint {
       return CGPoint(x: x * size.width, y: y * size.height)
   }
}
