//  MediaDomainModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 08/09/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

struct MediaDomainModel: Equatable {
    var id: String
    var index: Int
    var correlationId: String
    var relativePath: String
    var type: MediaType
    var url: URL {
        get {
            return URL.init(documentsWith: relativePath)
        }
    }
}

extension MediaDomainModel {
    init(media: Media, index: Int) {
        self.init(id: media.id, index: index, correlationId: media.correlationId, relativePath: media.relativePath, type: media.type)
    }
}
