//
//  UploadPageRequest.swift
//  zScanner
//
//  Created by Jakub Skořepa on 18/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct UploadPageReuest: Request, FileUploading {
    typealias DataType = EmptyResponse
    
    var endpoint: Endpoint = IkemEndpoint.uploadPage
    var method: HTTPMethod = .post
    var parameters: Parameters?
    var headers: HTTPHeaders = [:]
    var fileUrl: URL
    var boundary = "AaB03x"
    
    init(with page: PageNetworkModel) {
        parameters = page
        fileUrl = page.pageUrl
    }
}
