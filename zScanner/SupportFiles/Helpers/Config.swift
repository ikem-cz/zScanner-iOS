//
//  Config.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

enum Config {
    static let productionURL: String = "https://tempra.ikem.seacat"
    static let testingURL: String = "https://desolate-meadow-62603.herokuapp.com/api-zscanner/v3"
    
    static let currentEnvironment: Environment = .testing
    static let folderUsageHistoryCount = 3
}
