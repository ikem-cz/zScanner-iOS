//
//  FolderDomainModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 04/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

enum SearchType: String {
    case search = "searchResult"
    case suggested = "suggestedResult"
}

struct FolderDomainModel: Equatable {
    var externalId : String
    var id : String
    var name: String
    var type: SearchType? = nil
}

extension FolderDomainModel {
    static var notFound = FolderDomainModel(externalId: "", id: "", name: "folderResult.folderNotFound.title".localized, type: .search)
}

enum SearchMode: String {
    case history = "history"
    case search = "search"
    case scan = "scan"
}

extension FolderDomainModel: Hashable {
    static func == (lhs: FolderDomainModel, rhs: FolderDomainModel) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
