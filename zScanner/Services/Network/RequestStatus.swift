//
//  RequestStatus.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

enum RequestStatus<DataType>: Equatable {
    case progress(Double)
    case success(data: DataType)
    case error(RequestError)
    
    static func == (lhs: RequestStatus<DataType>, rhs: RequestStatus<DataType>) -> Bool {
        switch (lhs, rhs) {
        case (.progress, .progress), (.success, .success):
            return true
        case (.error(let left), .error(let right)):
            return left == right
        default:
            return false
        }
    }
}

// MARK: -
struct RequestError: Error, Equatable {
    let type: RequestErrorType
    let message: String?
    
    init(_ type: RequestErrorType, message: String? = nil) {
        self.type = type
        self.message = message
    }
}

// MARK: -
enum RequestErrorType: Equatable {
    case noInternetConnection
    case noData
    case serverError(Error)
    case jsonParserError
    case dataCorruptedError
    case seacatError
    case timeout
    case logicError
    
    var rawValue: String {
        switch self {
        case .noInternetConnection:
            return "noInternetConnection"
        case .noData:
            return "noData"
        case .serverError:
            return "serverError"
        case .jsonParserError:
            return "jsonParserError"
        case .dataCorruptedError:
            return "dataCorruptedError"
        case .seacatError:
            return "seacatError"
        case .timeout:
            return "timeout"
        case .logicError:
            return "logicError"
        }
    }
    
    static func == (lhs: RequestErrorType, rhs: RequestErrorType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

// MARK: -
struct HTTPError: Error {
    let errorCode: Int
}
