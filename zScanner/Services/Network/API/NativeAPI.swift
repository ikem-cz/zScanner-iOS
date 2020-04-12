//
//  NativeAPI.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import TUSKit

struct NativeAPI: API {
    
    static var uploads = [TUSResumableUpload]()
    static var tusSession: TUSSession?
    
    func process<R, D>(_ request: R, with callback: @escaping (RequestStatus<D>) -> Void) where R : Request, D : Decodable, D == R.DataType {
        guard reachability.connection != .unavailable else {
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
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        guard let configuration = SeaCatClient.getNSURLSessionConfiguration() else {
            callback(.error(RequestError(.seacatError)))
            return
        }
        
        let completionHandler: (Data?, URLResponse?, Error?) -> Void = { (data, response, error) in
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
        
        var task: URLSessionDataTask?
        
        if let uploadingRequest = request as? FileUploading {
            var upload: TUSResumableUpload?
            if NativeAPI.tusSession == nil {
                let uploadStore = TUSFileUploadStore()
                let session = TUSSession(
                    endpoint: URL(string: request.endpoint.url)!,
                    dataStore: uploadStore,
                    sessionConfiguration: configuration
                )
                NativeAPI.tusSession = session
            }
            
            var progressBlock: TUSUploadProgressBlock?
            var resultBlock: TUSUploadResultBlock?
            var failureBlock: TUSUploadFailureBlock?

            progressBlock = { bytesWritten, bytesTotal in
                let percentage = Double(bytesWritten) / Double(bytesTotal)
                callback(.progress(percentage))
            }
            
            resultBlock = { fileURL in
                callback(.success(data: EmptyResponse() as! D))
            }
            
            failureBlock = { error in
                callback(.error(RequestError(.serverError(error))))
            }
            
            let metadata: [String: String] = request.parameters?
                .properties()
                .compactMap({ $0 })
                .filter({ !($0.value is URL) })
                .reduce(into: [String: String]()) { (metadata, parameter) in
                    metadata[parameter.name] = String(describing: parameter.value)
                } ?? [:]

        
            upload = NativeAPI.tusSession?.createUpload(
                fromFile: uploadingRequest.fileUrl,
                retry: Config.numberOfTuskitRetries,
                headers: [:],
                metadata: metadata
            )
            upload?.progressBlock = progressBlock
            upload?.resultBlock = resultBlock
            upload?.failureBlock = failureBlock
            upload?.resume()
            upload.flatMap({ NativeAPI.uploads.append($0) })
        } else {
            let session = URLSession(configuration: configuration)
            task = session.dataTask(
                with: urlRequest as URLRequest,
                completionHandler: completionHandler
            )
            task?.resume()
        }
        
        callback(.progress(0))
    }
    
    // MARK: - Helpers
    private let reachability = try! Reachability()
}
