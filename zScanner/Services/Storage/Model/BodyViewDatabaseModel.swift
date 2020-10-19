//
//  BodyViewDatabaseModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 04/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RealmSwift

class BodyViewDatabaseModel: Object {
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    let bodyParts = List<BodyPartDatabaseModel>()
    
    convenience init(bodyView: BodyViewDomainModel) {
        self.init()
        
        self.id = bodyView.id
        self.name = bodyView.name
        self.bodyParts.append(objectsIn:
            bodyView
                .bodyParts
                .map({ BodyPartDatabaseModel(bodyPart: $0) })
        )
    }
}

//MARK: -
extension BodyViewDatabaseModel {
    func toDomainModel() -> BodyViewDomainModel {
        return BodyViewDomainModel(
            id: id,
            name: name,
            bodyParts: bodyParts.map { $0.toDomainModel() }
        )
    }
}
