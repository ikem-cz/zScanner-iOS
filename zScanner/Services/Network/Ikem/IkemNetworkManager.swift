//
//  IkemNetworkManager.swift
//  zScanner
//
//  Created by Jakub Skořepa on 28/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift

class IkemNetworkManager: NetworkManager {
    
    // MARK: Instance part
    private let api: API
    private let requestBehavior: RequestBehavior
    
    init(api: API, requestBehavior: RequestBehavior = EmptyRequestBehavior()) {
        self.api = api
        self.requestBehavior = requestBehavior
    }
    
    // MARK: Interface
    func submitPassword(_ auth: AuthNetworkModel) -> Observable<RequestStatus<EmptyResponse>> {
        return Observable.create { observer -> Disposable in
            var request = SubmitPasswordRequest(auth: auth)
            
            request.headers.merge(
                self.requestBehavior.additionalHeaders,
                uniquingKeysWith: { (current, _) in current }
            )
            
            self.requestBehavior.beforeSend()
            
            self.api.process(request, with: { [weak self] requestStatus in
                observer.onNext(requestStatus)
                
                switch requestStatus {
                case .progress:
                    break
                case .success:
                    self?.requestBehavior.afterSuccess()
                    observer.onCompleted()
                case .error(let error):
                    self?.requestBehavior.afterError(error)
                    observer.onError(error)
                }
            })
            
            return Disposables.create()
        }
    }
    
    func getDocumentTypes() -> Observable<RequestStatus<[DocumentTypeNetworkModel]>> {
        return Observable.create { observer -> Disposable in
            var request = DocumentTypesRequest()
            
            request.headers.merge(
                self.requestBehavior.additionalHeaders,
                uniquingKeysWith: { (current, _) in current }
            )
            
            self.requestBehavior.beforeSend()
            
            self.api.process(request, with: { [weak self] requestStatus in
                observer.onNext(requestStatus)
                
                switch requestStatus {
                case .progress:
                    break
                case .success:
                    self?.requestBehavior.afterSuccess()
                    observer.onCompleted()
                case .error(let error):
                    self?.requestBehavior.afterError(error)
                    observer.onError(error)
                }
            })
            
            return Disposables.create()
        }
    }
    
    func uploadDocument(_ document: DocumentNetworkModel) -> Observable<RequestStatus<EmptyResponse>> {
        return Observable.create { observer -> Disposable in
            var request = SubmitReuest(document: document)
            
            request.headers.merge(
                self.requestBehavior.additionalHeaders,
                uniquingKeysWith: { (current, _) in current }
            )
            
            self.requestBehavior.beforeSend()
            
            self.api.process(request, with: { [weak self] requestStatus in
                observer.onNext(requestStatus)
                
                switch requestStatus {
                case .progress:
                    break
                case .success:
                    self?.requestBehavior.afterSuccess()
                    observer.onCompleted()
                case .error(let error):
                    self?.requestBehavior.afterError(error)
                    observer.onError(error)
                }
            })
            
            return Disposables.create()
        }
    }
    
    func searchFolders(with query: String) -> Observable<RequestStatus<[FolderNetworkModel]>> {
        return Observable.create { observer -> Disposable in
            var request = SearchFoldersRequest(query: query)
            
            request.headers.merge(
                self.requestBehavior.additionalHeaders,
                uniquingKeysWith: { (current, _) in current }
            )
            
            self.requestBehavior.beforeSend()
            
            self.api.process(request, with: { [weak self] requestStatus in
                observer.onNext(requestStatus)
                
                switch requestStatus {
                case .progress:
                    break
                case .success:
                    self?.requestBehavior.afterSuccess()
                    observer.onCompleted()
                case .error(let error):
                    self?.requestBehavior.afterError(error)
                    observer.onError(error)
                }
            })
            
            return Disposables.create()
        }
    }
    
    func getFolder(with id: String) -> Observable<RequestStatus<FolderNetworkModel>> {
        return Observable.create { observer -> Disposable in
            var request = GetFolderRequest(with: id)
            
            request.headers.merge(
                self.requestBehavior.additionalHeaders,
                uniquingKeysWith: { (current, _) in current }
            )
            
            self.requestBehavior.beforeSend()
            
            self.api.process(request, with: { [weak self] requestStatus in
                observer.onNext(requestStatus)
                
                switch requestStatus {
                case .progress:
                    break
                case .success:
                    self?.requestBehavior.afterSuccess()
                    observer.onCompleted()
                case .error(let error):
                    self?.requestBehavior.afterError(error)
                    observer.onError(error)
                }
            })
            
            return Disposables.create()
        }
    }
    
    func uploadPage(_ page: PageNetworkModel) -> Observable<RequestStatus<EmptyResponse>> {
        return Observable.create { observer -> Disposable in
            var request = UploadPageReuest(with: page)
            
            request.headers.merge(
                self.requestBehavior.additionalHeaders,
                uniquingKeysWith: { (current, _) in current }
            )
            
            self.requestBehavior.beforeSend()
            
            self.api.upload(request, with: { [weak self] requestStatus in
                observer.onNext(requestStatus)
                
                switch requestStatus {
                case .progress:
                    break
                case .success:
                    self?.requestBehavior.afterSuccess()
                    observer.onCompleted()
                case .error(let error):
                    self?.requestBehavior.afterError(error)
                    observer.onError(error)
                }
            })
            
            return Disposables.create()
        }
    }
}
