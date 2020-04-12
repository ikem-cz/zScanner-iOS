//
//  UploadPageNetworkModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 18/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct PageNetworkModel: Encodable {
    var uploadType = "page"
    var filetype = "image/jpg"
    var correlation: String
    var page: Int
    var pageUrl: URL
    
    init(from domainModel: MediaDomainModel) {
        self.pageUrl = URL(documentsWith: domainModel.relativePath)
        self.page = domainModel.index
        self.correlation = domainModel.correlationId
    }
}
