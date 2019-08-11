//
//  DcumentTypeDatabaseModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 28/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RealmSwift

class DocumentTypeDatabaseModel: Object {
    @objc dynamic var id = ""
    @objc dynamic var name = ""
    @objc private dynamic var _mode = ""
    
    convenience init(documentType: DocumentTypeDomainModel) {
        self.init()
        
        self.id = documentType.id
        self.name = documentType.name
        self.mode = documentType.mode
    }
    override class func primaryKey() -> String {
        return "id"
    }
    
    var mode: DocumentMode {
        get { return DocumentMode(rawValue: _mode)! }
        set { self._mode = newValue.rawValue }
    }
}

//MARK: -
extension DocumentTypeDatabaseModel {
    func toDomainModel() -> DocumentTypeDomainModel {
        return DocumentTypeDomainModel(
            id: id,
            name: name,
            mode: mode
        )
    }
}
