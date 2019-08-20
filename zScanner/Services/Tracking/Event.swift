//
//  Event.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

enum Event {
    case login
    case logout
    
    case documentModeSelected(DocumentMode)
    
    case userFoundBy(SearchMode)
    case userNotFound
    
    // TODO: Četnosti jednotlivých typů záznamů (ambulantní zpráva, přijímají zpráva,...)
    case useOfDescription(Bool)
    
    // TODO: Swipe delete?
    case galleryUsed(Bool)
    
    case numberOfDocumentsBeforeDelete(Int)
    case createDocumentAgain
}
