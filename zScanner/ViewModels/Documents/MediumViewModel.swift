//
//  MediaViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 08/09/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift

class MediaViewModel {
    
    // MARK: Instance part
    private var networkManager: NetworkManager
    private var database: Database
    let page: Media
    let pageUploadStatus = BehaviorSubject<DocumentViewModel.UploadStatus>(value: .awaitingInteraction)
    
    
    init(page: Media, networkManager: NetworkManager, database: Database) {
        self.page = page
        
        self.networkManager = networkManager
        self.database = database
        
        if let databaseModel = database.loadObjects(PageUploadStatusDatabaseModel.self).filter({ $0.pageId == page.id }).first {
            pageUploadStatus.onNext(databaseModel.uploadStatus == .success ? .success : .failed(nil))
        }
    }
    
    // MARK: Interface
    func uploadPage() {
        guard (try? pageUploadStatus.value()) == .awaitingInteraction else {
            return
        }
        
        pageUploadStatus.onNext(.progress(0))
        setupBindings()
        
        let pageNetworkModel = PageNetworkModel(from: page)
        
        networkManager
            .uploadPage(pageNetworkModel)
            .subscribe(
                onNext: { [weak self] requestStatus in
                    switch requestStatus {
                    case .progress(let percentage):
                        self?.pageUploadStatus.onNext(.progress(percentage))
                    case .success:
                        self?.pageUploadStatus.onNext(.progress(1))
                        self?.pageUploadStatus.onNext(.success)
                    case .error(let error):
                        self?.pageUploadStatus.onNext(.failed(error))
                    }
                },
                onError: { [weak self] error in
                    self?.pageUploadStatus.onError(error)
                },
                onCompleted: { [weak self] in
                    self?.pageUploadStatus.onCompleted()
                }
            )
            .disposed(by: disposeBag)
    }
    
    func prepareForReupload() {
        if (try? pageUploadStatus.value()) == .failed(nil) {
            pageUploadStatus.onNext(.awaitingInteraction)
        }
    }
    
    // MARK: Helpers
    private let disposeBag = DisposeBag()
    
    private func setupBindings() {
        pageUploadStatus
            .asObservable()
            .observeOn(MainScheduler.instance)
            .do(afterCompleted: { [weak self] in self?.page.deleteMedia() })
            .subscribe(onNext: { [weak self]  status in
                guard let `self` = self else { return }
                let pageUploadStatus = PageUploadStatusDatabaseModel(pageId: self.page.id, status: status)
                self.database.saveObject(pageUploadStatus)
            })
            .disposed(by: disposeBag)
    }
}
