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
        let request = SubmitPasswordRequest(auth: auth)
        return observe(request)
    }
    
    func getStatus(_ token: TokenNetworkModel) -> Observable<RequestStatus<StatusResponseNetworkModel>> {
        let request = GetStatusRequest(token: token)
        return observe(request)
    }
    
    func getDocumentTypes() -> Observable<RequestStatus<[DocumentTypeNetworkModel]>> {
        let request = DocumentTypesRequest()
        return observe(request)
    }
    
    func uploadDocument(_ document: DocumentNetworkModel) -> Observable<RequestStatus<EmptyResponse>> {
        let request = SubmitReuest(document: document)
        return observe(request)
    }
    
    func searchFolders(with query: String) -> Observable<RequestStatus<[FolderNetworkModel]>> {
        let request = SearchFoldersRequest(with: QueryNetworkModel(query: query))
        return observe(request)
    }
    
    func getFolder(with id: String) -> Observable<RequestStatus<FolderNetworkModel>> {
        let request = GetFolderRequest(with: QueryNetworkModel(query: id))
        return observe(request)
    }
    
    func uploadPage(_ page: PageNetworkModel) -> Observable<RequestStatus<EmptyResponse>> {
        let request = UploadPageReuest(with: page)
        return observe(request)
    }
    
    func getBodyParts() -> Observable<RequestStatus<[BodyViewNetworkModel]>> {
        let request = GetBodyPartsRequest()
        return observe(request)
    }
    
    func getBodyImage(id: String) -> Observable<RequestStatus<BodyImageNetworkModel>> {
        let request = GetBodyViewImageRequest(id: id)
        return observe(request)
    }
    
    func getFolderDefects(folderId: String) -> Observable<RequestStatus<[BodyDefectNetworkModel]>> {
        let request = GetFolderDefectsRequest(folderId: folderId)
        return observe(request)
    }
    
    private func observe<T: Request, U: Decodable>(_ request: T) -> Observable<RequestStatus<U>> where T.DataType == U {
        return Observable.create { [weak self] observer -> Disposable in
            guard let `self` = self else { return Disposables.create() }
            
            var request = request
            
            request.headers.merge(
                self.requestBehavior.additionalHeaders,
                uniquingKeysWith: { (current, _) in current }
            )
            
            self.requestBehavior.beforeSend()
            
            self.api.process(request, with: { [weak self] requestStatus in
                switch requestStatus {
                case .progress:
                    observer.onNext(requestStatus)
                case .success:
                    self?.requestBehavior.afterSuccess()
                    observer.onNext(requestStatus)
                    observer.onCompleted()
                case .error(let error):
                    self?.requestBehavior.afterError(error)
                    observer.onNext(requestStatus)
                    observer.onError(error)
                }
            })
            
            return Disposables.create()
        }
    }
}
