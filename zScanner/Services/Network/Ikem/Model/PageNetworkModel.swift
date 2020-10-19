//
//  UploadPageNetworkModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 18/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct PageNetworkModel: Encodable {
    var uploadType: String
    var filetype: String
    var correlation: String
    var pageIndex: Int
    var description: String? = nil
    var defectId: String? = nil
    var defectName: String? = nil
    var bodyPartId: String? = nil
    
    var pageUrl: URL
    
    init(from domainModel: Media) {
        self.pageUrl = domainModel.cropUrl ?? domainModel.url
        self.pageIndex = domainModel.index!
        self.correlation = domainModel.correlationId
        self.description = domainModel.description
        
        switch domainModel.type {
        case .photo:
            uploadType = "pageWithDefect"
            filetype = "image/jpg"
        case .video:
            uploadType = "page"
            filetype = "video/mp4"
        case .scan:
            uploadType = "page"
            filetype = "image/jpg"
        }
        
        if let defect = domainModel.defect {
            self.defectId = defect.id
            
            if defect.isNew {
                self.defectName = defect.title
                self.bodyPartId = defect.bodyPartId
            }
        }
    }
}
