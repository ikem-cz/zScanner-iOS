//
//  Request.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

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
        
        if let properties = parameters?.properties() {
            let encodedProperties = properties.compactMap({ (key, value) -> String? in
                guard let value = String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
                return String(format: "%@=%@", key, value)
            }).joined(separator: "&")
            url += "?" + encodedProperties
        }
        
        return url
    }
}

// MARK: -
protocol ParametersJsonEncoded {}

// MARK: -
protocol ImageConverting {
    init(image: UIImage)
}


// MARK: -
protocol FileUploading {
    var fileUrl: URL { get }
    var boundary: String { get }
}
