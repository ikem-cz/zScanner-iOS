//
//  IkemEndpoint.swift
//  zScanner
//
//  Created by Jakub Skořepa on 28/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

enum IkemEndpoint: Endpoint {
    case documentTypes
    case submitDocument
    case uploadPage
    case folderSearch
    case folderDecode
    case submitPassword
    case seaCatStatus
    case bodyViews
    case bodyViewImage(String)
    case folderDefects(String)
    
    var rawValue: String {
        switch self {
            case .documentTypes: return "/documenttypes"
            case .submitDocument: return "/documents/summary"
            case .uploadPage: return "/upload"
            case .folderSearch: return "/folders/search"
            case .folderDecode: return "/folders/decode"
            case .submitPassword: return "/password"
            case .seaCatStatus: return "/status"
            case .bodyViews: return "/bodyparts/views"
            case .bodyViewImage(let viewId): return "/bodyparts/views/\(viewId)/image"
            case .folderDefects(let folderId): return "/folders/\(folderId)/defects"
        }
    }
    
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
