//
//  Media.swift
//  zScanner
//
//  Created by Jan Provazník on 18/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import AVFoundation

class Media {
    let id: String
    let type: MediaType
    let correlationId: String
    let relativePath: String
    let url: URL
    let fromGallery: Bool
    var thumbnail: UIImage?
    
    func makeVideoThumbnail() {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        let timestamp = CMTime(seconds: 1, preferredTimescale: 60)

        do {
            let imageRef = try generator.copyCGImage(at: timestamp, actualTime: nil)
            thumbnail = UIImage(cgImage: imageRef)
        } catch let error as NSError {
            print("Video snapshot generation failed with error \(error)")
        }
    }
    
    init(type: MediaType, correlationId: String, fromGallery: Bool, thumbnail: UIImage? = nil) {
        self.id = UUID().uuidString
        self.type = type
        self.correlationId = correlationId
        self.relativePath = correlationId + "/" + id + type.suffix
        self.url = URL(documentsWith: relativePath)
        self.fromGallery = fromGallery
        self.thumbnail = thumbnail
    }
}

extension Media: Equatable {
    static func == (lhs: Media, rhs: Media) -> Bool {
        return lhs.id == rhs.id
    }
}
