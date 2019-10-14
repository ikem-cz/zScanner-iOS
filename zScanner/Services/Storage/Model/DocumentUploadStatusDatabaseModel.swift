//
//  DocumentUploadStatusDatabaseModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 09/09/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RealmSwift

class DocumentUploadStatusDatabaseModel: Object {
    @objc dynamic var documentId = ""
    @objc private dynamic var _uploadStatus = -1
    
    convenience init(documentId: String, status: DocumentViewModel.UploadStatus) {
        self.init()
        
        self.documentId = documentId
        self.uploadStatus = status
    }
    
    var uploadStatus: DocumentViewModel.UploadStatus {
        get {
            return DocumentViewModel.UploadStatus(rawValue: _uploadStatus) ?? .awaitingInteraction
        }
        set {
            _uploadStatus = newValue.rawValue
        }
    }
    
    override class func primaryKey() -> String {
        return "documentId"
    }
}
