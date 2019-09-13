//
//  PageDatabaseModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 08/09/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RealmSwift

class PageDatabaseModel: Object {
    @objc dynamic var url = ""
    @objc dynamic var index = 0
    @objc dynamic var correlationId = ""
    @objc private dynamic var primaryKey = ""
    
    convenience init(page: PageDomainModel) {
        self.init()
        
        self.correlationId = page.correlationId
        self.index = page.index
        self.url = page.url.absoluteString
        self.primaryKey = String(format: "%dx%@", index, correlationId)
    }
    
    override class func primaryKey() -> String {
        return "primaryKey"
    }
}

extension PageDatabaseModel {
    func toDomainModel() -> PageDomainModel {
        return PageDomainModel(
            url: URL(string: url)!,
            index: index,
            correlationId: correlationId
        )
    }
}

extension PageDatabaseModel: RichDeleting {
    func deleteRichContent() {
        try? FileManager.default.removeItem(at: URL(string: url)!)
    }
}
