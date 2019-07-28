//
//  IkemNetworkManaging.swift
//  zScanner
//
//  Created by Jakub Skořepa on 28/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

protocol IkemNetworkManaging {

    /// Fetch all document subtypes
    /// - Parameter callback: Closure for async request status update
    func getDocumentTypes(callback: @escaping RequestClosure<[DocumentTypeNetworkModel]>)
}
