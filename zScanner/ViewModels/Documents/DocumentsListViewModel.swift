//
//  DocumentsListViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 21/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift

class DocumentsListViewModel {
    enum DocumentModesState {
        case awaitingInteraction
        case loading
        case success
        case error(Error)
    }
    
    //MARK: Instance part
    private let database: Database
    private let networkManager: NetworkManager
    
    private(set) var documents: [DocumentViewModel] = []
    private(set) var documentModes: [DocumentMode] = []
    
    init(database: Database, ikemNetworkManager: NetworkManager) {
        self.database = database
        self.networkManager = ikemNetworkManager
        
        loadDocuments()
        fetchDocumentTypes()
    }
    
    //MARK: Interface
    let documentModesState = BehaviorSubject<DocumentModesState>(value: .awaitingInteraction)
    
    func insertNewDocument(_ document: DocumentViewModel) {
        documents.insert(document, at: 0)
    }
    
    func updateDocuments() {
        
        // Find all documents with active upload
        let activeUploadDocuments = documents.filter({
            if let status = try? $0.documentUploadStatus.value() {
                return status != .success
            }
            return false
        })
        
        loadDocuments()
        
        // Replace all dummy* documents with active upload to show the process in UI.
        // *dummy document is document loaded from DB without active upload process
        for activeDocument in activeUploadDocuments {
            let _ = documents.remove(activeDocument)
            documents.insert(activeDocument, at: 0)
        }
    }
    
    //MARK: Helpers
    let disposeBag = DisposeBag()
    
    private func loadDocuments() {
        documents = database
            .loadObjects(DocumentDatabaseModel.self)
            .map({ DocumentViewModel(document: $0.toDomainModel()) })
            .reversed()
    }
    
    private func fetchDocumentTypes() {
        networkManager.getDocumentTypes().subscribe(onNext: { [weak self] requestStatus in
            switch requestStatus {
            case .loading(let percentage):
                self?.documentModesState.onNext(.loading(percentage))
                
            case .success(data: let networkModel):
                let documents = networkModel.map({ $0.toDomainModel() })
                
                self?.storeDocumentTypes(documents)
                self?.storeDocumentModes(from: documents)
                
                self?.documentModesState.onNext(.success)

            case .error(let error):
                self?.documentModesState.onNext(.error(error))
            }
        }).disposed(by: disposeBag)
    }
    
    private func storeDocumentModes(from documentTypes: [DocumentTypeDomainModel]) {
        documentModes = Array(Set(documentTypes.map({ $0.mode })))
        documentModes.append(.photo)
    }
    
    private func storeDocumentTypes(_ types: [DocumentTypeDomainModel]) {
        DispatchQueue.main.async {
            self.database.deleteAll(of: DocumentTypeDatabaseModel.self)
            types
                .map({ DocumentTypeDatabaseModel(documentType: $0) })
                .forEach({ self.database.saveObject($0) })
        }
    }
}
