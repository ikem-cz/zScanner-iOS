//
//  BodyPartDatabaseModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 04/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RealmSwift

class BodyPartDatabaseModel: Object {
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc dynamic var locationX: Double = 0.0
    @objc dynamic var locationY: Double = 0.0
    
    convenience init(bodyPart: BodyPartDomainModel) {
        self.init()
        
        self.id = bodyPart.id
        self.name = bodyPart.name
        self.locationX = Double(bodyPart.location.x)
        self.locationY = Double(bodyPart.location.y)
    }
}

//MARK: -
extension BodyPartDatabaseModel {
    func toDomainModel() -> BodyPartDomainModel {
        return BodyPartDomainModel(
            id: id,
            name: name,
            location: CGPoint(x: locationX, y: locationY)
        )
    }
}
