//
//  Themes.swift
//  zScanner
//
//  Created by Jan Provazník on 14/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

enum Theme {
    case dark
    case light
}

protocol ThemeProtocol {
    var navigationBarTintColor: UIColor { get } // Color of navigation controller items
    var navigationBarTitleTextAttributes: [NSAttributedString.Key : Any]? { get }
    var navigationBarBarStyle: UIBarStyle { get }// Background-color of the navigation controller, which automatically adapts the color of the status bar (time, battery ..)
}

struct DarkTheme: ThemeProtocol {
    var navigationBarTintColor: UIColor { return .white }
    var navigationBarTitleTextAttributes: [NSAttributedString.Key : Any]? { return [.foregroundColor: UIColor.white] }
    var navigationBarBarStyle: UIBarStyle { return .black }
}

struct LightTheme: ThemeProtocol {
    var navigationBarTintColor: UIColor { return .black }
    var navigationBarTitleTextAttributes: [NSAttributedString.Key : Any]? { return nil }
    var navigationBarBarStyle: UIBarStyle { return .default }
}
