//
//  UploadPageNetworkModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 18/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct PageNetworkModel: Encodable {
    var uploadType = "pageWithDefect"
    var filetype = "image/jpg"
    var correlation: String
    var pageIndex: Int
    var decription: String? = nil
    var defectId: String? = nil
    var defectName: String? = nil
    var bodyPartId: String? = nil
    
    var pageUrl: URL
    
    init(from domainModel: Media) {
        self.pageUrl = domainModel.url
        self.pageIndex = domainModel.index!
        self.correlation = domainModel.correlationId
        self.decription = domainModel.desription
        
        if let defect = domainModel.defect {
            self.defectId = defect.id
            
            if defect.isNew {
                self.defectName = defect.title
                self.bodyPartId = defect.bodyPartId
            }
        }
    }
}
