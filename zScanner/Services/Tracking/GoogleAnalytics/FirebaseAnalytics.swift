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
        case .login: return "login"
        case .logout: return "logout"
            
        case .documentModeSelected: return "newDocument"
            
        case .userFoundBy: return "userFound"
        case .userNotFound: return "userNotFound"
            
        case .deleteImage: return "deleteImage"
        case .galleryUsed(let used): return used ? "galleryUsed" : "cameraUsed"
        
        case .numberOfDocumentsBeforeDelete: return "numberOfDocumentsBeforeDelete"
        case .createDocumentAgain: return "createDocumentAgain"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .documentModeSelected(let mode):
            return ["documentMode": mode.rawValue]
        case .userFoundBy(let mode):
            return ["searchType": mode.rawValue]
        case .numberOfDocumentsBeforeDelete(let sum):
            return ["numberOfDocuments": sum]
        default:
            return [:]
        }
    }
}
