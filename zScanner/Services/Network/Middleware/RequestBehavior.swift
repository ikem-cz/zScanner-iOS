//
//  RequestBehavior.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

protocol RequestBehavior {
    var additionalHeaders: [String: String] { get }
    func beforeSend()
    func afterSuccess()
    func afterError(_ error: RequestError)
}

//MARK: -
extension RequestBehavior {
    var additionalHeaders: [String: String] { return [:] }
    func beforeSend() {}
    func afterSuccess() {}
    func afterError(_ error: RequestError) {}
}

//MARK: -
struct EmptyRequestBehavior: RequestBehavior { }

//MARK: -
struct CombinedRequestBehavior: RequestBehavior {
    
    let behaviors: [RequestBehavior]
    
    var additionalHeaders: [String : String] {
        return behaviors.reduce([String: String](), { sum, behavior in
            return sum.merging(behavior.additionalHeaders, uniquingKeysWith: { (current, _) in current })
        })
    }
    
    func beforeSend() {
        behaviors.forEach({ $0.beforeSend() })
    }
    
    func afterSuccess() {
        behaviors.forEach({ $0.afterSuccess() })
    }
    
    func afterError(_ error: RequestError) {
        behaviors.forEach({ $0.afterError(error) })
    }
}
