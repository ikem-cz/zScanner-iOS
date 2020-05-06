//
//  NewDocumentPhotosViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 14/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

class NewDocumentMediaViewModel<MediaType: Equatable> {
    
    // MARK: Instance part
    private let tracker: Tracker
    let folderName: String
    
    init(tracker: Tracker, folderName: String) {
        self.tracker = tracker
        self.folderName = folderName
    }
    
    // MARK: Interface
    let mediaArray = BehaviorRelay<[MediaType]>(value: [])
    
    func addMedia(_ media: MediaType, fromGallery: Bool) {
        // Tracking
        tracker.track(.galleryUsed(fromGallery))
        
        // Add image
        var newArray = mediaArray.value
        newArray.append(media)
        mediaArray.accept(newArray)
    }
    
    func removeMedia(_ media: MediaType) {
        // Tracking
        tracker.track(.deleteImage)

        // Remove image
        var newArray = mediaArray.value
        _ = newArray.remove(media)
        mediaArray.accept(newArray)
    }
}
