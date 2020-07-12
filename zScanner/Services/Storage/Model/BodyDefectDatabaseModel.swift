//
//  BodyDefectDatabaseModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 10/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RealmSwift

class BodyDefectDatabaseModel: Object {
    @objc dynamic var id = ""
    @objc dynamic var title = ""
    @objc dynamic var bodyPartId = ""
    @objc dynamic var isNew = false
    
    convenience init(bodyDefect: BodyDefectDomainModel) {
        self.init()
        
        self.id = bodyDefect.id
        self.title = bodyDefect.title
        self.bodyPartId = bodyDefect.bodyPartId
        self.isNew = bodyDefect.isNew
    }
}

//MARK: -
extension BodyDefectDatabaseModel {
    func toDomainModel() -> BodyDefectDomainModel {
        return BodyDefectDomainModel(
            id: id,
            title: title,
            bodyPartId: bodyPartId,
            isNew: isNew
        )
    }
}
