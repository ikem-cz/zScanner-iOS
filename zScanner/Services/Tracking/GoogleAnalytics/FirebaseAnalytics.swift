//
//  GoogleAnalytics.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import FirebaseAnalytics

class FirebaseAnalytics: Tracker {

    func track(_ event: Event) {
        Analytics.logEvent(event.id, parameters: event.parameters)
    }
}

extension Event {
    var id: String {
        switch self {
            case .documentModeSelected: return "newDocument"
            case .login: return "login"
            case .logout: return "logout"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .documentModeSelected(let mode):
            return ["documentMode": mode.rawValue]
        default:
            return [:]
        }
    }
}
