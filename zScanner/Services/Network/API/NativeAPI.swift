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
        callback(.progress(0))
    }
    
    private var uploads = [UploadDelegate]()
    
    func upload<R>(_ request: R, with callback: @escaping (RequestStatus<EmptyResponse>) -> Void) where R: Request, R.DataType == EmptyResponse {
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
        
        guard let fileUrl = (request as? UploadFileURL)?.fileUrl, let imageData = try? Data(contentsOf: fileUrl) else {
            callback(.error(RequestError(.dataCorruptedError)))
            return
        }
        
        let requestBody: Data
        
        if request is ParametersJsonEncoded {
            requestBody = createBodyWithParameters(parameters: request.parameters, fileUrl: fileUrl, imageDataKey: imageData, boundary: "AaB03x")
        } else {
            requestBody = imageData
        }
        
        let uploadDelegate = UploadDelegate(callback: callback)
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300
        configuration.timeoutIntervalForResource = 300
        let session = URLSession(configuration: configuration, delegate: uploadDelegate, delegateQueue: .main)
        let task = session.uploadTask(
            with: urlRequest as URLRequest,
            from: requestBody,
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
                
                callback(.success(data: EmptyResponse()))
            }
        )
    
        task.resume()
        callback(.progress(0))
    }
    
    private func createBodyWithParameters(parameters: Encodable?, fileUrl: URL, imageDataKey: Data, boundary: String) -> Data {
        var body = Data()

        // TODO: Do it more generic
        if let page = parameters as? PageNetworkModel {
            body.append(string: "--\(boundary)\r\n")
            body.append(string: "Content-Disposition: form-data; name=\"correlation\"\r\n\r\n")
            body.append(string: "\(page.correlation)\r\n")
            body.append(string: "--\(boundary)\r\n")
            body.append(string: "Content-Disposition: form-data; name=\"page\"\r\n\r\n")
            body.append(string: "\(page.page)\r\n")
        }

        let filename = fileUrl.lastPathComponent
        let mimetype = "image/jpg"

        body.append(string: "--\(boundary)\r\n")
        body.append(string: "Content-Disposition: form-data; name=\"page\"; filename=\"\(filename)\"\r\n")
        body.append(string: "Content-Type: \(mimetype)\r\n\r\n")
        body.append(imageDataKey)
        body.append(string: "\r\n")

        body.append(string: "--\(boundary)--\r\n")

        return body
    }
}

// MARK: -
private class UploadDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    
    // TODO: Debug lifecyle of UploadDelegate (deinit), put class to separated file
    let callback: (RequestStatus<EmptyResponse>) -> Void
    
    init(callback: @escaping (RequestStatus<EmptyResponse>) -> Void) {
        self.callback = callback
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let percentage = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        callback(.progress(percentage))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        callback(.error(RequestError(.serverError(error!))))
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("")
    }
}
