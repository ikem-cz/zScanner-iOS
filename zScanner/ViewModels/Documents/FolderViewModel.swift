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


final class FolderViewModel {
    typealias UploadStatus = DocumentViewModel.UploadStatus

    // MARK: Instance part
    let folder: FolderDomainModel
    let documents: BehaviorRelay<[DocumentViewModel]>
    var folderStatus = BehaviorRelay<UploadStatus>(value: .awaitingInteraction)
    
    init(folder: FolderDomainModel, documents: [DocumentViewModel]) {
        self.folder = folder
        self.documents = BehaviorRelay(value: documents)
        
        setupBindings()
    }
    
    func reupload() {
        documents.value.forEach({ $0.reupload() })
    }
    
    func cleanUp() {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1) {
            var newDocuments = self.documents.value
            let finishedDocuments = newDocuments.filter({ $0.documentUploadStatus.value == .success })
            for document in finishedDocuments {
                _ = newDocuments.remove(document)
                document.delete()
            }
            self.documents.accept(newDocuments)
        }
    }
    
    private lazy var statusToProgress: ([UploadStatus]) -> UploadStatus = { [weak self] tasks in
        var progresses = [Double]()
        var inProgressCount = 0
        var awaitingCount = 0
        var failed = false
        var error: RequestError?
        
        for status in tasks {
            switch status {
            case .awaitingInteraction:
                awaitingCount += 1
                progresses.append(0)
            case .progress(let percentage):
                inProgressCount += 1
                progresses.append(percentage)
            case .success:
                progresses.append(1)
            case .failed(let e):
                failed = true
                error = e
                progresses.append(0)
            }
        }

        if inProgressCount == 0 && awaitingCount == 0 {
            if failed {
                return .failed(error)
            } else {
                return .success
            }
        }
        
        let overallProgress = progresses.reduce(0, { $0 + $1 }) / Double(progresses.count)
        return .progress(overallProgress)
    }
    
    // MARK: Helpers
    private let disposeBag = DisposeBag()
    private var folderStatusSubscription: Disposable?
    
    private func setupBindings() {
        documents.subscribe(onNext: { [weak self] documents in
            guard let self = self else { return }
            
            let tasks = documents.filter({ $0.documentUploadStatus.value != .success }).map({
                $0.documentUploadStatus.asObservable()
            })
            
            self.folderStatusSubscription?.dispose()
            self.folderStatusSubscription = Observable
                .combineLatest(tasks)
                .skip(1)
                .map(self.statusToProgress)
                .subscribe(onNext: { [weak self] status in
                    self?.folderStatus.accept(status)
                })
        })
        .disposed(by: disposeBag)
    }
    
    func insertNewDocument(_ newDocument: DocumentViewModel) {
        var newArray = documents.value
        let _ = newArray.first(where: { $0.document.id == newDocument.document.id }).flatMap({ newArray.remove($0) })
        newArray.insert(newDocument, at: 0)
        documents.accept(newArray)
    }
}

extension FolderViewModel: Hashable {
    static func == (lhs: FolderViewModel, rhs: FolderViewModel) -> Bool {
        return lhs.folder.id == rhs.folder.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(folder.id)
    }
}
