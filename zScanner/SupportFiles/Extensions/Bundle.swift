//
//  Bundle.swift
//  zScanner
//
//  Created by Jakub Skořepa on 22/09/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    
    var formattedVersion: String {
        guard let version = releaseVersionNumber, let build = buildVersionNumber else { return "1.0.0 (1)" }
        
        return String(format: "v%@ (%@)", version, build)
    }
}
