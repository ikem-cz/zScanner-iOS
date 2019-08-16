//
//  NativeAPI.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

struct NativeAPI: API {
    
    func process<R, D>(_ request: R, with callback: @escaping (RequestStatus<D>) -> Void) where R : Request, D : Decodable, D == R.DataType {
        callback(.loading(1))

        guard Reachability.isConnectedToNetwork() else {
            callback(.error(RequestError(.noInternetConnection)))
            return
        }
        
        let urlString: String
        switch request {
        case let encoded as ParametersURLEncoded:
            urlString = encoded.encodedUrl
        default:
            urlString = request.endpoint.url
        }
        
        guard let url = URL(string: urlString) else {
            callback(.error(RequestError(.dataCorruptedError)))
            return
        }
        
        let urlRequest = NSMutableURLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        request.headers.forEach({ urlRequest.addValue($0.value, forHTTPHeaderField: $0.key) })
        
        if request is ParametersJsonEncoded {
            urlRequest.httpBody = request.parameters?.toJSONData()
        }
        
        let session = URLSession.shared
        let task = session.dataTask(
            with: urlRequest as URLRequest,
            completionHandler: { (data, response, error) in
                if let error = error {
                    callback(.error(RequestError(.serverError(error))))
                    return
                }
                
                // handle HTTP errors here
                if let httpResponse = response as? HTTPURLResponse {
                    let statusCode = httpResponse.statusCode
                    
                    if statusCode < 200 || statusCode >= 300 {
                        callback(.error(RequestError(.serverError(HTTPError(errorCode: statusCode)))))
                        return
                    }
                }
                
                if D.self is EmptyResponse.Type {
                    callback(.success(data: EmptyResponse() as! D))
                    return
                }
                
                guard let data = data, !data.isEmpty else {
                    callback(.error(RequestError(.noData)))
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let objects = try decoder.decode(D.self, from: data)
                    callback(.success(data: objects))
                } catch {
                    callback(.error(RequestError(.jsonParserError)))
                }
            }
        )
        task.resume()
    }
}
