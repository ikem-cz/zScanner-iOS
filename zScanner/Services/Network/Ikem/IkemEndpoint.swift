//
//  IkemEndpoint.swift
//  zScanner
//
//  Created by Jakub Skořepa on 28/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

enum IkemEndpoint: String, Endpoint {
    case documentTypes = "/documenttypes"
    
    var url: String {
        return baseUrl + self.rawValue
    }
    
    private var baseUrl: String {
        return Config.currentEnvironment.baseUrl
    }
}
