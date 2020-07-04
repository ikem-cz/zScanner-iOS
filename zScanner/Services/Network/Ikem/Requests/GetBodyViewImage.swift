//
//  GetBodyViewImage.swift
//  zScanner
//
//  Created by Jakub Skořepa on 04/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

struct GetBodyViewImage: Request {
    typealias DataType = BodyImageNetworkModel
    
    var endpoint: Endpoint
    var method: HTTPMethod = .get
    var parameters: Parameters? = nil
    var headers: HTTPHeaders = [:]
    
    init(id: String) {
        endpoint = IkemEndpoint.bodyViewImage(id)
    }
}
