//
//  GetStatusRequest.swift
//  zScanner
//
//  Created by Jakub Skořepa on 03/09/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct GetStatusRequest: Request, ParametersJsonEncoded {
    typealias DataType = StatusResponseNetworkModel
    
    var endpoint: Endpoint = IkemEndpoint.seaCatStatus
    var method: HTTPMethod = .post
    var parameters: Parameters?
    var headers: HTTPHeaders = [:]
    
    init(token: TokenNetworkModel) {
        parameters = token
    }
}
