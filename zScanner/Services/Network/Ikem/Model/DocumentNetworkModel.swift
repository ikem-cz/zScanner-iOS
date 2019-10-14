//
//  DocumentNetworkModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 06/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct DocumentNetworkModel: Encodable {
    var correlation: String
    var folderInternalId: String
    var documentMode: String
    var documentType: String
    var pages: Int
    var datetime: String
    var name: String
    var notes: String
    
    init(from domainModel: DocumentDomainModel) {
        self.correlation = domainModel.id
        self.folderInternalId = domainModel.folder.id
        self.documentMode = domainModel.type.mode.rawValue
        self.documentType = domainModel.type.id
        
        self.pages = domainModel.pages.count
        self.datetime = domainModel.date.utcString
        self.name = domainModel.type.name
        self.notes = domainModel.notes
    }
}
