//
//  IkemNetworkManaging.swift
//  zScanner
//
//  Created by Jakub Skořepa on 28/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift

protocol IkemNetworkManaging {

    /// Fetch all document subtypes
    /// - Parameter callback: Closure for async request status update
    func getDocumentTypes() -> Observable<RequestStatus<[DocumentTypeNetworkModel]>>
    
    
    /// Upload document to server
    /// - Parameter document: New document to upload
    /// - Parameter callback: Closure for async request status update
    func uploadDocument(_ document: DocumentNetworkModel) -> Observable<RequestStatus<EmptyResponse>>
}
