//
//  GetFolderRequest.swift
//  zScanner
//
//  Created by Jakub Skořepa on 11/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct GetFolderRequest: Request, ParametersURLEncoded {
    typealias DataType = FolderNetworkModel
    
    var endpoint: Endpoint = IkemEndpoint.folderDecode
    var method: HTTPMethod = .get
    var parameters: Parameters?
    var headers: HTTPHeaders = [:]
    
    init(with id: String) {
        parameters = ["query": id]
    }
}
