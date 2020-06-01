//
//  DocumentTypeDomainModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 28/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

enum MediaType: Equatable {
    case photo
    case video
    case scan
    
    var description: String {
        switch self {
            case .photo: return "newDocumentPhotos.mediaType.photo".localized
            case .video: return "newDocumentPhotos.mediaType.video".localized
            case .scan: return "newDocumentPhotos.mediaType.scan".localized
        }
    }
    
    var suffix: String {
        switch self {
        case .photo, .scan: return ".jpg"
        case .video: return ".mp4"
        }
    }
}

enum DocumentMode: String, SegmentItem {
    case ext
    case document = "doc"
    case examination = "exam"
    case photo
    case video
    case undefined
    
    var title: String {
        return "documentMode.\(self.rawValue).name".localized
    }
}

// MARK: -
struct DocumentTypeDomainModel {
    var id: String
    var name: String
    var mode: DocumentMode
}

// MARK: ListItem implementation
extension DocumentTypeDomainModel: ListItem {
    var title: String {
        return name
    }
}

// MARK: -
typealias DocumentDict = [DocumentMode: [DocumentTypeDomainModel]]
