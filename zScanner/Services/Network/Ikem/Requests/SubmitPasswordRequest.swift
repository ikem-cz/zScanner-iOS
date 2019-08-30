//
//  SubmitPasswordRequest.swift
//  zScanner
//
//  Created by Jakub Skořepa on 26/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct SubmitPasswordRequest: Request, ParametersJsonEncoded {
    typealias DataType = EmptyResponse
    
    var endpoint: Endpoint = IkemEndpoint.submitPassword
    var method: HTTPMethod = .post
    var parameters: Parameters?
    var headers: HTTPHeaders = [:]
    
    init(auth: AuthNetworkModel) {
        parameters = auth
    }
}
