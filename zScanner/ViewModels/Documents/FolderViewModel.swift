//
//  FolderViewModel.swift
//  zScanner
//
//  Created by Jan Provazník on 21/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay


class FolderViewModel {
    typealias UploadStatus = DocumentViewModel.UploadStatus

    // MARK: Instance part
    private var networkManager: NetworkManager
    private var database: Database
    private var documents = BehaviorRelay<[DocumentViewModel]>(value: [])
    let folder: FolderDomainModel
    
    private lazy var statusToProgress: ([UploadStatus]) -> UploadStatus = { [weak self] tasks in
        return .success
    }
    
    lazy var folderStatus: Observable<UploadStatus> = Observable
        .combineLatest(tasks)
        .map(statusToProgress)
        .asObservable()
    
    private var tasks: [Observable<UploadStatus>] {
        documents.value.map({ $0.documentUploadStatus.asObservable() })
    }
    
    init(folder: FolderDomainModel, networkManager: NetworkManager, database: Database) {
        self.folder = folder
        self.networkManager = networkManager
        self.database = database
        
        print(folder.documents)
    }
    
    func insertNewDocument(_ document: DocumentViewModel) {
        var newArray = documents.value
        newArray.append(document)
        documents.accept(newArray)
    }
    
    func loadDocuments() {
        let newDocuments = folder.documents.map { DocumentViewModel(document: $0, networkManager: networkManager, database: database) }
        documents.accept(newDocuments)
    }
}

extension FolderViewModel: Hashable {
    static func == (lhs: FolderViewModel, rhs: FolderViewModel) -> Bool {
        return lhs.folder == rhs.folder
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(folder)
    }
}
