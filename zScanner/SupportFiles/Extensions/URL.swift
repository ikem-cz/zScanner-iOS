//
//  URL.swift
//  zScanner
//
//  Created by Jakub Skořepa on 16/09/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

extension URL {
    static var documentsPath: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    init(documentsWith relativePath: String) {
        self.init(fileURLWithPath: URL.documentsPath + "/" + relativePath)
    }
}
