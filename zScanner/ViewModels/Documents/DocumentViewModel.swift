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
    enum UploadStatus: RawRepresentable, Equatable {
        case awaitingInteraction
        case progress(Double)
        case success
        case failed(RequestError?)
        
        typealias RawValue = Int
        
        init?(rawValue: Int) {
            switch rawValue {
                case 0: self = .awaitingInteraction
                case 1: self = .progress(0)
                case 2: self = .success
                case 3: self = .failed(nil)
                default: return nil
            }
        }
        
        var rawValue: Int {
            switch self {
                case .awaitingInteraction: return 0
                case .progress: return 1
                case .success: return 2
                case .failed: return 3
            }
        }
    }
    
    // MARK: Instance part
    private var networkManager: NetworkManager
    private var database: Database
    let document: DocumentDomainModel
    private let internalUploadStatus = BehaviorSubject<DocumentViewModel.UploadStatus>(value: .awaitingInteraction)
    
    private var uploadTasks = [Observable<RequestStatus<EmptyResponse>>]()
    private let pages: [PageViewModel]
    
    init(document: DocumentDomainModel, networkManager: NetworkManager, database: Database) {
        self.document = document
        
        self.networkManager = networkManager
        self.database = database
        
        pages = document.pages.map({ PageViewModel(page: $0, networkManager: networkManager, database: database) })
        
        if let databaseModel = database.loadObjects(DocumentUploadStatusDatabaseModel.self).filter({ $0.documentId == document.id }).first {
            internalUploadStatus.onNext(databaseModel.uploadStatus == .success ? .success : .failed(nil))
        }        
    }
    
    // MARK: Interface
    func uploadDocument() {
        internalUploadStatus.onNext(.progress(0))
        setupBindings()
        
        let networkDocument = DocumentNetworkModel(from: document)
        networkManager
            .uploadDocument(networkDocument)
            .subscribe(onNext: { [weak self] requestStatus in
                switch requestStatus {
                case .progress(let percentage):
                    self?.internalUploadStatus.onNext(.progress(percentage))
                case .success:
                    self?.internalUploadStatus.onNext(.progress(1))
                    self?.internalUploadStatus.onNext(.success)
                case .error(let error):
                    self?.internalUploadStatus.onNext(.failed(error))
                }
            }, onError: { [weak self] error in
                self?.internalUploadStatus.onError(error)
            }, onCompleted: { [weak self] in
                self?.internalUploadStatus.onCompleted()
            })
            .disposed(by: disposeBag)
        
        pages.forEach({ $0.uploadPage() })
    }
    
    lazy var documentUploadStatus: Observable<UploadStatus> = Observable
        .combineLatest(tasks)
        .map(statusToProgress)
        .asObservable()
    
    // MARK: Helpers
    private let disposeBag = DisposeBag()
    
    private func setupBindings() {
        internalUploadStatus
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self]  status in
                guard let `self` = self else { return }
                let databaseUploadStatus = DocumentUploadStatusDatabaseModel(documentId: self.document.id, status: status)
                self.database.saveObject(databaseUploadStatus)
            })
            .disposed(by: disposeBag)
    }
    
    private var tasks: [Observable<UploadStatus>] {
        var tasks: [Observable<UploadStatus>] = pages.map({ $0.pageUploadStatus.asObservable() })
        tasks.append(internalUploadStatus.asObservable())
        return tasks
    }
    
    private let statusToProgress: ([UploadStatus]) -> UploadStatus = { tasks in
        
        var progresses = [Double]()
        var stillInProgress = false
        var failed = false
        var error: RequestError?
        
        for status in tasks {
            switch status {
            case .awaitingInteraction:
                progresses.append(0)
            case .progress(let percentage):
                stillInProgress = true
                progresses.append(percentage * 0.9)
            case .success:
                progresses.append(1)
            case .failed(let e):
                failed = true
                error = e
                progresses.append(0)
            }
        }
        
        if !stillInProgress {
            if failed {
                return .failed(error)
            } else {
                return .success
            }
        }
        
        let overallProgress = progresses.reduce(0, { $0 + $1 }) / Double(progresses.count)
        return .progress(overallProgress)
    }
}

extension DocumentViewModel: Equatable {
    static func == (lhs: DocumentViewModel, rhs: DocumentViewModel) -> Bool {
        return lhs.document == rhs.document
    }
}
