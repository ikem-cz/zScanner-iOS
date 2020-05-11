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
    case submitDocument = "/documents/summary"
    case uploadPage = "/upload"
    case folderSearch = "/folders/search"
    case folderDecode = "/folders/decode"
    case submitPassword = "/password"
    case seaCatStatus = "/status"
    
    var url: String {
        switch self {
        case .submitPassword, .seaCatStatus:
            return authUrl + self.rawValue
        case .uploadPage:
            return "https://tempra.ikem.seacat/api-zscanner-new/upload"
        default:
            return baseUrl + self.rawValue
        }
    }
    
    private var baseUrl: String {
        return Config.currentEnvironment.baseUrl
    }
    
    private var authUrl: String {
        return Config.currentEnvironment.authUrl
    }
}
