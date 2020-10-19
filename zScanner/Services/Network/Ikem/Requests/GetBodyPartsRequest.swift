//
//  GetBodyPartsRequest.swift
//  zScanner
//
//  Created by Jakub Skořepa on 04/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct GetBodyPartsRequest: Request {
    typealias DataType = [BodyViewNetworkModel]
    
    var endpoint: Endpoint = IkemEndpoint.bodyViews
    var method: HTTPMethod = .get
    var parameters: Parameters? = nil
    var headers: HTTPHeaders = [:]
    
    init() {}
}
