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
    @objc dynamic var id = ""
    @objc dynamic var url = ""
    @objc dynamic var index = 0
    @objc dynamic var correlationId = ""
    
    convenience init(page: PageDomainModel) {
        self.init()
        
        self.id = page.id
        self.correlationId = page.correlationId
        self.index = page.index
        self.url = page.url.absoluteString
    }
    
    override class func primaryKey() -> String {
        return "id"
    }
}

extension PageDatabaseModel {
    func toDomainModel() -> PageDomainModel {
        return PageDomainModel(
            id: id,
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
