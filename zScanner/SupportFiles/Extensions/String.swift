//
//  String.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return localized(withComment: "")
    }
    
    func localized(withComment comment: String) -> String {
        return NSLocalizedString(self, comment: comment)
    }
}
