//
//  CameraViewModel.swift
//  zScanner
//
//  Created by Jan Provazník on 07/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import RxRelay

struct Media {
    let id: String
    let type: MediaType
    let correlationId: String
    let relativePath: String
    let url: URL
    let thumbnail: UIImage?
    let fromGallery: Bool
}

extension Media {
    init(type: MediaType, correlationId: String, fromGallery: Bool, thumbnail: UIImage? = nil) {
        #warning("Should create variable for suffix in Config file?")
        let suffix = type == .photo ? ".jpg" : ".mp4"
        let id = UUID().uuidString
        let relativePath = correlationId + "/" + id + suffix
        let absoluteURL = URL(documentsWith: relativePath)
        
        self.init(id: id, type: type, correlationId: correlationId, relativePath: relativePath, url: absoluteURL, thumbnail: thumbnail, fromGallery: fromGallery)
    }
}


class CameraViewModel {
    
    // MARK: Instance part
    let currentMode: BehaviorRelay<MediaType>
    
    let folderName: String
    let correlationId: String
    let mediaSourceTypes: [MediaType]
    
    var media: Media?
    
    init(initialMode currentMode: MediaType, folderName: String, correlationId: String, mediaSourceTypes: [MediaType]) {
        self.currentMode = BehaviorRelay<MediaType>(value: currentMode)
        self.folderName = folderName
        self.correlationId = correlationId
        self.mediaSourceTypes = mediaSourceTypes
    }
    
    func createDocumentDirectory() {
        let absolutePath = URL.documentsPath + correlationId
        if !FileManager.default.fileExists(atPath: absolutePath) {
            try! FileManager.default.createDirectory(atPath: absolutePath, withIntermediateDirectories: false, attributes: nil)
        }
    }
    
    // MARK: Interface
    func saveImage(image: UIImage, fromGallery: Bool) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        do {
            media = Media(type: .photo, correlationId: correlationId, fromGallery: fromGallery, thumbnail: image)
            createDocumentDirectory()
            try data.write(to: media!.url)
        } catch let error {
            print("error saving image with error", error)
        }
    }
    
    func saveVideo(fromGallery: Bool, url: URL? = nil)  {
        media = Media(type: .video, correlationId: correlationId, fromGallery: fromGallery)
        
        DispatchQueue.global(qos: .background).async {
            // Copy video to documents folder
            if fromGallery, let url = url {
                do {
                    let videoData = try Data(contentsOf: url)
                    self.createDocumentDirectory()
                    try videoData.write(to: self.media!.url)
                } catch(let error) {
                    print("Could not copy video to documents folder: \(error)")
                }
            }
        }
    }
    
    func newModeSelected(with mode: MediaType) {
        currentMode.accept(mode)
    }
}
