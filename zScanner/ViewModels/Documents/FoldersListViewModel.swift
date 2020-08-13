//
//  DocumentsListViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 21/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

class FoldersListViewModel {
    
    //MARK: Instance part
    private let database: Database
    private let networkManager: NetworkManager
    let login: LoginDomainModel
    
    var foldersUpdated: EmptyClosure?
    
    private(set) var folders: [FolderViewModel] = []
    private(set) var activeFolders: [FolderViewModel] = []
    private(set) var sentFolders: [FolderViewModel] = []
    
    private(set) var documentModes: [DocumentMode] = []
    
    init(database: Database, login: LoginDomainModel, ikemNetworkManager: NetworkManager) {
        self.database = database
        self.login = login
        self.networkManager = ikemNetworkManager
        
        loadFolders()
        setupBindings()
    }
    
    //MARK: Interface
    func insertNewDocument(_ documentViewModel: DocumentViewModel) {
        if let folder = activeFolders.first(where: { return $0.folder.id == documentViewModel.document.folderId }) {
            folder.insertNewDocument(documentViewModel)
        } else if let folder = sentFolders.first(where: { return $0.folder.id == documentViewModel.document.folderId }) {
            folder.insertNewDocument(documentViewModel)
            _ = sentFolders.remove(folder)
            activeFolders.append(folder)
            foldersUpdated?()
        } else {
            let databaseFolder = database.loadObject(FolderDatabaseModel.self, withId: documentViewModel.document.folderId)!
            let folder = FolderViewModel(folder: databaseFolder.toDomainModel(), documents: [documentViewModel])
            folders.append(folder)
            activeFolders.append(folder)
            subscribeFolderStatus(folder)
            foldersUpdated?()
        }
    }
    
    func updateFolders() {
        loadFolders()
        foldersUpdated?()
    }
    
    //MARK: Helpers
    private func setupBindings() {
        folders.forEach { subscribeFolderStatus($0) }
    }
    
    private func addActiveUpload(_ folder: FolderViewModel) {
        folders.append(folder)
        activeFolders.append(folder)
        subscribeFolderStatus(folder)
        foldersUpdated?()
    }
    
    private func subscribeFolderStatus(_ folder: FolderViewModel) {
        folder.folderStatus
            .skip(1)
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak folder] status in
                if status == .success, let folder = folder {
                    folder.cleanUp()
                    _ = self?.activeFolders.remove(folder)
                    self?.sentFolders.append(folder)
                    self?.foldersUpdated?()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private let disposeBag = DisposeBag()
    
    private func loadFolders() {
        folders = database
            .loadObjects(FolderDatabaseModel.self)
            .sorted(by: { $0.lastUsed > $1.lastUsed })
            .map({ FolderViewModel(folder: $0.toDomainModel(), documents: documents(for: $0.id)) })
        
        activeFolders = []
        sentFolders = []
        
        for folder in folders {
            if folder.folderStatus.value == .success {
                sentFolders.append(folder)
            } else {
                activeFolders.append(folder)
            }
        }
    }
    
    private func documents(for folderId: String) -> [DocumentViewModel] {
        let existingDocuments = folders.first(where: { $0.folder.id == folderId })?.documents.value ?? []
            
        let activeUploadDocuments = existingDocuments.filter({
            var currentStatus: DocumentViewModel.UploadStatus?
            $0.documentUploadStatus.subscribe(onNext: { status in currentStatus = status }).disposed(by: disposeBag)
            return currentStatus == .awaitingInteraction || currentStatus?.isInProgress == true
        })
        
        var newDocuments = database
            .loadObjects(DocumentDatabaseModel.self)
            .filter({ $0.folder?.id == folderId })
            .map({ DocumentViewModel(document: $0.toDomainModel(), networkManager: networkManager, database: database) })
        
        // Replace all dummy* documents with active upload to show the process in UI.
        // *dummy document is document loaded from DB without active upload process
        for activeDocument in activeUploadDocuments {
            let _ = newDocuments.remove(activeDocument)
            newDocuments.insert(activeDocument, at: 0)
        }
        
        return newDocuments
    }
}
