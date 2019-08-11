//
//  Request.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

protocol Request {
    associatedtype DataType: Any
    
    var endpoint: Endpoint { get }
    var method: HTTPMethod { get }
    var parameters: Parameters? { get set }
    var headers: HTTPHeaders { get set }
}

// MARK: -
struct EmptyResponse: Decodable {}

//MARK: -
protocol ParametersURLEncoded {
    var encodedUrl: String { get }
}

//MARK: - Default implementation
extension ParametersURLEncoded where Self: Request {
    var encodedUrl: String {
        var url = endpoint.url
        
        // Add parameters to url
        if let parameters = parameters as? [String: Any] {
            let parameters = parameters.map({ (key, value) -> String in "\(key)=\(value)" }).joined(separator: "&")
            url += "?" + parameters
        }
        
        return url
    }
}

// MARK: -
protocol ParametersJsonEncoded {}
