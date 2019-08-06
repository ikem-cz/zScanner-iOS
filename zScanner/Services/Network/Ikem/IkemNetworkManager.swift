//
//  IkemNetworkManager.swift
//  zScanner
//
//  Created by Jakub Skořepa on 28/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

class IkemNetworkManager: IkemNetworkManaging {
    
    // MARK: Instance part
    private let api: API
    private let requestBehavior: RequestBehavior
    
    init(api: API, requestBehavior: RequestBehavior = EmptyRequestBehavior()) {
        self.api = api
        self.requestBehavior = requestBehavior
    }
    
    // MARK: Interface
    func getDocumentTypes(callback: @escaping RequestClosure<[DocumentTypeNetworkModel]>) {
        var request = DocumentTypesRequest()
        
        request.headers.merge(
            requestBehavior.additionalHeaders,
            uniquingKeysWith: { (current, _) in current }
        )
        
        requestBehavior.beforeSend()
        
        api.process(request, with: { [weak self] requestStatus in
            callback(requestStatus)
            
            switch requestStatus {
                case .loading: break
                case .success: self?.requestBehavior.afterSuccess()
                case .error(let error): self?.requestBehavior.afterError(error)
            }
        })
    }
    
    func uploadDocument(_ document: DocumentNetworkModel, callback: @escaping RequestClosure<EmptyResponse>) {
        var request = SubmitReuest(document: document)
        
        request.headers.merge(
            requestBehavior.additionalHeaders,
            uniquingKeysWith: { (current, _) in current }
        )
        
        requestBehavior.beforeSend()
        
        api.process(request, with: { [weak self] requestStatus in
            callback(requestStatus)
            
            switch requestStatus {
                case .loading: break
                case .success: self?.requestBehavior.afterSuccess()
                case .error(let error): self?.requestBehavior.afterError(error)
            }
        })
    }
}
