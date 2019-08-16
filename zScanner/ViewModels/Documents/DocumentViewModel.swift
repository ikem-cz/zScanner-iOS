//
//  DocumentViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 21/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift

class DocumentViewModel {
    enum DocumentUploadStatus: Equatable {
        case awaitingInteraction
        case progress(Double)
        case success
        case failed
    }
    
    // MARK: Instance part
    private var networkManager: NetworkManager?
    let document: DocumentDomainModel
    let documentUploadStatus = BehaviorSubject<DocumentUploadStatus>(value: .awaitingInteraction)
    
    init(document: DocumentDomainModel) {
        self.document = document
        documentUploadStatus.onNext(.success)
    }
    
    // MARK: Interface
    func uploadDocument(with networkManager: NetworkManager) {
        self.networkManager = networkManager
        
        documentUploadStatus.onNext(.progress(0))
        
        let networkDocument = DocumentNetworkModel(from: document)
        networkManager.uploadDocument(networkDocument).subscribe(onNext: { [weak self] status in
            switch status {
            case .loading(let percentage):
                self?.documentUploadStatus.onNext(.progress(percentage))
            case .success:
                self?.documentUploadStatus.onNext(.progress(1))
                self?.documentUploadStatus.onNext(.success)
                self?.documentUploadStatus.onCompleted()
            case .error(let error):
                self?.documentUploadStatus.onNext(.failed)
                self?.documentUploadStatus.onError(error)
            }
        }).disposed(by: disposeBag)
    }
    
    // MARK: Helpers
    private let disposeBag = DisposeBag()
}

extension DocumentViewModel: Equatable {
    static func == (lhs: DocumentViewModel, rhs: DocumentViewModel) -> Bool {
        return lhs.document == rhs.document
    }
}
