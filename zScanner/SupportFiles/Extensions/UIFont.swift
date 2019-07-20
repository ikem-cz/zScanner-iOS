//
//  UIFont.swift
//  zScanner
//
//  Created by Jakub Skořepa on 20/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

import UIKit

extension UIFont {
    
    static var headline: UIFont {
        let font = UIFont.systemFont(ofSize: 22, weight: .bold)
        return UIFontMetrics(forTextStyle: .headline).scaledFont(for: font)
    }
    
    static var body: UIFont {
        let font = UIFont.systemFont(ofSize: 17, weight: .regular)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
    }
    
    static var light: UIFont {
        let font = UIFont.systemFont(ofSize: 17, weight: .light)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
    }
}
