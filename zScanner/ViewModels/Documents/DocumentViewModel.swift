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
    var uploadTasks = [Observable<RequestStatus<EmptyResponse>>]()
    
    init(document: DocumentDomainModel) {
        self.document = document
        documentUploadStatus.onNext(.success)
    }
    
    // MARK: Interface
    func uploadDocument(with networkManager: NetworkManager) {
        self.networkManager = networkManager
        
        documentUploadStatus.onNext(.progress(0))
        
        let networkDocument = DocumentNetworkModel(from: document)
        let task = networkManager.uploadDocument(networkDocument)
        uploadTasks.append(task)
        
        document.pages.enumerated().forEach({ (index, url) in
            let page = PageNetworkModel(correlation: document.id, page: index, pageUrl: url)
            let task = networkManager.uploadPage(page)
            uploadTasks.append(task)
        })
        
        let statusToProgress: ([RequestStatus<EmptyResponse>]) -> DocumentUploadStatus = { tasks in
            
            var progresses = [Double]()
            var stillInProgress = false
            
            for taskStatus in tasks {
                switch taskStatus {
                case .progress(let percentage):
                    stillInProgress = true
                    progresses.append(percentage)
                case .success:
                    progresses.append(1)
                case .error:
                    return .failed
                }
            }
            
            if !stillInProgress {
                return .success
            }
            
            let overallProgress = progresses.reduce(0, { $0 + $1 }) / Double(progresses.count)
            return .progress(overallProgress)
        }
        
        Observable
            .combineLatest(uploadTasks)
            .map(statusToProgress)
            .subscribe(onNext: { [unowned self] element in
                self.documentUploadStatus.onNext(element)
            }, onError: { [unowned self] error in
                //self.documentUploadStatus.onNext(.progress(0))
                self.documentUploadStatus.onNext(.failed)
                self.documentUploadStatus.onError(error)
            }, onCompleted: { [unowned self] in
                self.documentUploadStatus.onNext(.progress(1))
                self.documentUploadStatus.onNext(.success)
                self.documentUploadStatus.onCompleted()
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
