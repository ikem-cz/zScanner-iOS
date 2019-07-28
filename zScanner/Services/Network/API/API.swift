//
//  API.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

protocol API {
    func process<R, D>(_ request: R, with callback: @escaping (RequestStatus<D>) -> Void) where R: Request, D: Decodable, D == R.DataType
}

//MARK: -
enum HTTPMethod: String {
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case delete  = "DELETE"
}

//MARK: -
typealias Parameters = [String: Any]

//MARK: -
typealias HTTPHeaders = [String: String]


