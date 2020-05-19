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
    
    private func createDocumentDirectory() {
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
    
    func saveVideo(fromGallery: Bool, url: URL? = nil, _ completion: @escaping (Bool) -> ())  {
        media = Media(type: .video, correlationId: correlationId, fromGallery: fromGallery)
        
        createDocumentDirectory()
        
        if fromGallery, let url = url {
            DispatchQueue.global(qos: .background).async {
            // Copy video to documents folder
                do {
                    let videoData = try Data(contentsOf: url)
                    try videoData.write(to: self.media!.url)
                    completion(true)
                } catch(let error) {
                    print("Could not copy video to documents folder: \(error)")
                    completion(false)
                }
            }
        } else {
            completion(true)
        }
    }
    
    func newModeSelected(with mode: MediaType) {
        currentMode.accept(mode)
    }
}
