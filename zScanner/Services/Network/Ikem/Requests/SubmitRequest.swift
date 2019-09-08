//
//  SubmitRequest.swift
//  zScanner
//
//  Created by Jakub Skořepa on 06/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct SubmitReuest: Request, ParametersJsonEncoded {
    typealias DataType = EmptyResponse
    
    var endpoint: Endpoint = IkemEndpoint.submitDocument
    var method: HTTPMethod = .post
    var parameters: Parameters?
    var headers: HTTPHeaders = [:]
    
    init(document: DocumentNetworkModel) {
        parameters = document
    }
}
