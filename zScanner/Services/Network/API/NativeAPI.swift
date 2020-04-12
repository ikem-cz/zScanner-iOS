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
        
//        guard let configuration = SeaCatClient.getNSURLSessionConfiguration() else {
//            callback(.error(RequestError(.seacatError)))
//            return
//        }
        let configuration = URLSessionConfiguration.default
        
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
        var upload: TUSResumableUpload?
        
        if let uploadingRequest = request as? FileUploading {
            let page = (request as! UploadPageReuest).parameters as! PageNetworkModel
            
            
            var uploadStore: TUSUploadStore? = nil
            
            var progressBlock:TUSUploadProgressBlock?
            var resultBlock:TUSUploadResultBlock?
            var failureBlock:TUSUploadFailureBlock?
 
            if NativeAPI.tusSession == nil {
            uploadStore = TUSFileUploadStore()
                let session = TUSSession(endpoint: URL(string: request.endpoint.url)!, dataStore: uploadStore!, sessionConfiguration: configuration)
                
                NativeAPI.tusSession = session
                
            }

            progressBlock = { bytesWritten, bytesTotal in
                print( "progress : \(bytesWritten) / \(bytesTotal)"  )
               // uploadUIHandle.setProgress(progress: Int(bytesWritten), max: Int(bytesTotal))
            }
            resultBlock = { fileURL in
                // Use the upload url
                print("result uploaded url: \(fileURL)")
            }
            failureBlock = { error in
                print(error)
            }
    
            upload = NativeAPI.tusSession?.createUpload(
                fromFile: uploadingRequest.fileUrl,
                retry: 3,
                headers: [:],
                metadata: [
                    "filetype": "image/jpg",
                    "uploadType": "page",
                    "pageIndex": String(page.page),
                    "correlation": page.correlation
                ]
            )
            upload?.progressBlock = progressBlock
            upload?.resultBlock = resultBlock
            upload?.failureBlock = failureBlock
            
//            guard let requestBody = createBody(for: uploadingRequest, parameters: request.parameters) else {
//                callback(.error(RequestError(.dataCorruptedError)))
//                return
//            }
//
//            let uploadDelegate = UploadDelegate(callback: { status in
//                if case let .progress(percentage) = status {
//                    callback(.progress(percentage))
//                }
//            })
//
//            urlRequest.addValue("multipart/form-data; boundary=\(uploadingRequest.boundary)", forHTTPHeaderField: "Content-Type")
//
//            configuration.timeoutIntervalForRequest = 300
//            configuration.timeoutIntervalForResource = 300
//            let session = URLSession(configuration: configuration, delegate: uploadDelegate, delegateQueue: .main)
//
//            task = session.uploadTask(
//                with: urlRequest as URLRequest,
//                from: requestBody,
//                completionHandler: completionHandler
//            )
        } else {
            let session = URLSession(configuration: configuration)
            task = session.dataTask(
                with: urlRequest as URLRequest,
                completionHandler: completionHandler
            )
        }
        task?.resume()
        upload?.resume()
        upload.flatMap({ NativeAPI.uploads.append($0) })
        
        NativeAPI.uploads.forEach({ print($0.state.rawValue) })
        
        callback(.progress(0))
    }
    
    
    // MARK: - Helpers
    private let reachability = try! Reachability()
    
    private func createBody(for request: FileUploading, parameters: Encodable?) -> Data? {
        var body = Data()
            
        if let properties = parameters?.properties().compactMap({ $0 }).filter({ !($0.value is URL) }) {
            for property in properties {
                body.append(string: "--\(request.boundary)\r\n")
                body.append(string: "Content-Disposition: form-data; name=\"\(property.name)\"\r\n\r\n")
                body.append(string: "\(String(describing: property.value))")
                body.append(string: "\r\n")
            }
        }
    
        guard let imageData = try? Data(contentsOf: request.fileUrl) else {
            return nil
        }
        
        let filename = request.fileUrl.lastPathComponent
        let mimetype = "image/jpg"

        body.append(string: "--\(request.boundary)\r\n")
        body.append(string: "Content-Disposition: form-data; name=\"page\"; filename=\"\(filename)\"\r\n")
        body.append(string: "Content-Type: \(mimetype)\r\n\r\n")
        body.append(imageData)
        body.append(string: "\r\n")
        body.append(string: "--\(request.boundary)--\r\n")

        return body
    }
}

// MARK: -
private class UploadDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    
    // TODO: Debug lifecyle of UploadDelegate (when is called deinit = released from the memory)
    // TODO: Put class to separated file
    
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
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {}
}
