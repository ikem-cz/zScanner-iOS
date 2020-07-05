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
    @objc dynamic var index = 0
    @objc dynamic var correlationId = ""
    @objc dynamic var relativePath = ""
    @objc dynamic var cropRelativePath: String? = nil
    
    convenience init(media: Media) {
        self.init()
        
        self.id = media.id
        self.correlationId = media.correlationId
        self.index = media.index!
        self.relativePath = media.relativePath
        self.cropRelativePath = media.cropRelativePath
    }
    
    override class func primaryKey() -> String {
        return "id"
    }
}

extension PageDatabaseModel {
    func toDomainModel() -> Media {
        return Media(
            id: id,
            index: index,
            type: .photo,
            correlationId: correlationId,
            relativePath: relativePath,
            cropRelativePath: cropRelativePath
        )
    }
}

extension PageDatabaseModel: RichDeleting {
    func deleteRichContent() {
        try? FileManager.default.removeItem(at: URL(documentsWith: relativePath))
        cropRelativePath.flatMap { try? FileManager.default.removeItem(at: URL(documentsWith: $0)) }
    }
}
