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
    enum DocumentModesState {
        case awaitingInteraction
        case loading
        case success
        case error(RequestError)
    }
    
    //MARK: Instance part
    private let database: Database
    private let networkManager: NetworkManager
    let login: LoginDomainModel
    
    private(set) var folders: [FolderViewModel] = []
    private(set) var activeFolders = BehaviorRelay<[FolderViewModel]>(value: [])
    private(set) var sentFolders = BehaviorRelay<[FolderViewModel]>(value: [])
//    private(set) var documentModes: [DocumentMode] = []
    
    init(database: Database, login: LoginDomainModel, ikemNetworkManager: NetworkManager) {
        self.database = database
        self.login = login
        self.networkManager = ikemNetworkManager
        
        loadFolders()
//        fetchDocumentTypes()
    }
    
    //MARK: Interface
    let documentModesState = BehaviorSubject<DocumentModesState>(value: .awaitingInteraction)
    
    func insertNewDocument(_ documentViewModel: DocumentViewModel) {
        if let folder = activeFolders.value.first(where: { return $0.folder.id == documentViewModel.document.id }) {
            folder.insertNewDocument(documentViewModel)
            return
        }
        
        guard let folder = sentFolders.value.first(where: { return $0.folder.id == documentViewModel.document.id }) else {
            print("Couldn't insert document because can't find relevant folder")
            return
        }
        folder.insertNewDocument(documentViewModel)
    }
    
//    func updateDocumentTypes() {
//        fetchDocumentTypes()
//    }
    
    func setDocumentAsSent(_ folder: FolderViewModel) {
//        newArray = sentDocuments.value
//        newArray.insert(document, at: 0)
//        sentDocuments.accept(newArray)
    }
    
    func updateFolders() {
        // Find all folders with active upload documents
         let activeUploadFolderDocuments = folders.filter({
            var currentStatus: DocumentViewModel.UploadStatus?
            $0.folderStatus.subscribe(onNext: { status in currentStatus = status }).disposed(by: disposeBag)
            return currentStatus == .awaitingInteraction || currentStatus == .progress(0) // Any progress, parameter is not considered when comparing
        })
        
        loadFolders()
        
        // Replace all dummy* documents with active upload to show the process in UI.
        // *dummy document is document loaded from DB without active upload process
        for activeFolder in activeUploadFolderDocuments {
            let _ = folders.remove(activeFolder)
            folders.insert(activeFolder, at: 0)
        }
        
        // Filter folders by status
        activeFolders.accept(folders.filter({
                var status: DocumentViewModel.UploadStatus?
                $0.folderStatus.subscribe(onNext: { stat in status = stat }).disposed(by: disposeBag)
                return status! != .success
            })
        )

        sentFolders.accept(folders.filter({
                var status: DocumentViewModel.UploadStatus?
                $0.folderStatus.subscribe(onNext: { stat in status = stat }).disposed(by: disposeBag)
                return status! == .success
            })
        )
    }
    
    //MARK: Helpers
    let disposeBag = DisposeBag()
    
    private func loadFolders() {
        folders = database
                 .loadObjects(FolderDatabaseModel.self)
                 .map({ FolderViewModel(folder: $0.toDomainModel(), networkManager: networkManager, database: database) })
                 .reversed()
    }
    
//    func fetchDocumentTypes() {
//        networkManager
//            .getDocumentTypes()
//            .subscribe(onNext: { [weak self] requestStatus in
//                switch requestStatus {
//                case .progress:
//                    self?.documentModesState.onNext(.loading)
//
//                case .success(data: let networkModel):
//                    let documents = networkModel.map({ $0.toDomainModel() })
//
//                    self?.storeDocumentTypes(documents)
//                    self?.storeDocumentModes(from: documents)
//
//                    self?.documentModesState.onNext(.success)
//
//                case .error(let error):
//                    self?.documentModesState.onNext(.error(error))
//                }
//            })
//            .disposed(by: disposeBag)
//    }
    
//    private func storeDocumentModes(from documentTypes: [DocumentTypeDomainModel]) {
//        documentModes = Array(Set(documentTypes.map({ $0.mode })))
//        documentModes.append(.photo)
//        documentModes.append(.video)
//    }
    
//    private func storeDocumentTypes(_ types: [DocumentTypeDomainModel]) {
//        DispatchQueue.main.async {
//            self.database.deleteAll(of: DocumentTypeDatabaseModel.self)
//            types
//                .map({ DocumentTypeDatabaseModel(documentType: $0) })
//                .forEach({ self.database.saveObject($0) })
//        }
//    }
}
