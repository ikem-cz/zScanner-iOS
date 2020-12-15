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
            case .submitPassword: return "/password"
            case .seaCatStatus: return "/status"
      
            case .documentTypes: return "/v3/documenttypes"
            case .submitDocument: return "/v3/documents/summary"
            case .folderSearch: return "/v3/folders/search"
            case .folderDecode: return "/v3/folders/decode"
            case .bodyViews: return "/v3/bodyparts/views"
            case .bodyViewImage(let viewId): return "/v3/bodyparts/views/\(viewId)/image"
            case .folderDefects(let folderId): return "/v3/folders/\(folderId)/defects"
            case .uploadPage: return "/upload"
        }
    }
    
    var url: String {
        switch self {
        case .submitPassword, .seaCatStatus:
            return authUrl + self.rawValue
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
