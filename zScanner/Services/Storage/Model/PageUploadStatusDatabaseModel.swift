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
    @objc dynamic var correlationId = ""
    @objc dynamic var index = -1
    @objc private dynamic var _uploadStatus = -1
    @objc private dynamic var primaryKey = ""
    
    convenience init(viewModel: PageViewModel) {
        self.init()
        
        self.correlationId = viewModel.page.correlationId
        self.index = viewModel.page.index
        self.uploadStatus = (try? viewModel.pageUploadStatus.value()) ?? .awaitingInteraction
        self.primaryKey = String(format: "%dx%@", index, correlationId)
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
        return "primaryKey"
    }
}
