//
//  IkemNetworkManaging.swift
//  zScanner
//
//  Created by Jakub Skořepa on 28/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift

protocol NetworkManager {

    /// Fetch all document subtypes
    func getDocumentTypes() -> Observable<RequestStatus<[DocumentTypeNetworkModel]>>
    
    
    /// Upload document to server
    /// - Parameter document: New document to upload
    func uploadDocument(_ document: DocumentNetworkModel) -> Observable<RequestStatus<EmptyResponse>>
    
    
    /// Search folders on backend
    /// - Parameter query: Part of the folder external id or name to search
    func searchFolders(with query: String) -> Observable<RequestStatus<[FolderNetworkModel]>>
    
    /// Search folders on backend
    /// - Parameter id: Part of the folder external id or name to search
    func getFolder(with id: String) -> Observable<RequestStatus<FolderNetworkModel>>
}
