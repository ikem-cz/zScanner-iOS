//
//  DocumentTypeDomainModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 28/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

enum DocumentMode: String {
    case document = "doc"
    case examination = "exam"
    case photo = "photo"
    case undefined = "undefined"
    
    var title: String {
        return "documentMode.\(self.rawValue).name".localized
    }
}

// MARK: -
struct DocumentTypeDomainModel {
    var id: String
    var name: String
    var mode: DocumentMode
}

// MARK: ListItem implementation
extension DocumentTypeDomainModel: ListItem {
    var title: String {
        return name
    }
}

// MARK: -
typealias DocumentDict = [DocumentMode: [DocumentTypeDomainModel]]
