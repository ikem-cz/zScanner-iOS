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
import AVFoundation

class MediaViewModel {
    
    // MARK: Instance part
    private let tracker: Tracker
    let mediumType: MediaType
    let folderName: String
    
    init(folderName: String, mediumType: MediaType, tracker: Tracker) {
        self.tracker = tracker
        self.mediumType = mediumType
        self.folderName = folderName
    }
    
    // MARK: Interface
    let mediaArray = BehaviorRelay<[URL: UIImage]>(value: [:])
    
    private func getVideoSnapshot(videoURL: URL) -> UIImage? {
        let asset = AVURLAsset(url: videoURL)
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
    
    func getPhotoSnapshot(photoURL: URL) -> UIImage? {
        do {
            let data = try Data(contentsOf: photoURL)
            return UIImage(data: data)
        } catch(let error) {
            print("Could not load data from url: ", error)
            return nil
        }
    }
    
    func getMediaSnapshot(mediumURL: URL) -> UIImage? {
        switch mediumType {
        case .photo:
            return getPhotoSnapshot(photoURL: mediumURL)
        case .video:
            return getVideoSnapshot(videoURL: mediumURL)
        default:
            print(mediumType.description, " is not implemented yet")
            return nil
        }
    }
    
    func addMedia(_ mediumURL: URL, fromGallery: Bool) {
        // Tracking
        tracker.track(.galleryUsed(fromGallery))
        
        // Add medium with snapshot
        var newDict = mediaArray.value
        if let mediaSnapshot = getMediaSnapshot(mediumURL: mediumURL) {
            newDict[mediumURL] = mediaSnapshot
        }
        mediaArray.accept(newDict)
    }
    
    func removeMedia(_ mediumURL: URL) {
        // Tracking
        tracker.track(.deleteImage)

        // Remove medium
        var newDict = mediaArray.value
        _ = newDict.removeValue(forKey: mediumURL)
        mediaArray.accept(newDict)
    }
}
