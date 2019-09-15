//
//  PageUploadStatusDatabaseModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 10/09/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RealmSwift

class PageUploadStatusDatabaseModel: Object {
    @objc dynamic var pageId = ""
    @objc private dynamic var _uploadStatus = -1
    
    convenience init(pageId: String, status: DocumentViewModel.UploadStatus) {
        self.init()
        
        self.pageId = pageId
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
        return "pageId"
    }
}
