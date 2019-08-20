//
//  FolderDomainModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 04/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct FolderDomainModel {
    var externalId : String
    var id : String
    var name: String
}

enum SearchMode: String {
    case history = "history"
    case search = "search"
    case scan = "scan"
}
