//
//  GetFolderDefectsRequest.swift
//  zScanner
//
//  Created by Jakub Skořepa on 05/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct GetFolderDefectsRequest: Request {
    typealias DataType = [BodyDefectNetworkModel]
    
    var endpoint: Endpoint
    var method: HTTPMethod = .get
    var parameters: Parameters? = nil
    var headers: HTTPHeaders = [:]
    
    init(folderId: String) {
        endpoint = IkemEndpoint.folderDefects(folderId)
    }
}
