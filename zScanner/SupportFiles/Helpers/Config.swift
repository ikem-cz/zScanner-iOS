//
//  Config.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

enum Config {
    static let productionURL: String = "https://tempra.ikem.seacat/api-zscanner/v3"
    static let testingURL: String = "https://zscanner.ikem.dev.bindworks.eu/api-zscanner/v3"
    static let authUrl: String = "http://auth.ikem.seacat"
    
    static let currentEnvironment: Environment = .testing
    static let folderUsageHistoryCount = 3
    static let minimumSearchLength = 3
    static let maximumNumberOfConcurentUploads = 4
    static let maximumSecondsOfVideoRecording: Double = 5
    static let numberOfTuskitRetries: Int32 = 3
}

//MARK: -
enum Environment {
    case production
    case testing
    
    var baseUrl: String {
        switch self {
            case .production: return Config.productionURL
            case .testing: return Config.testingURL
        }
    }
    
    var authUrl: String {
        switch self {
            case .production: return Config.authUrl
            case .testing: return ""
        }
    }
}
