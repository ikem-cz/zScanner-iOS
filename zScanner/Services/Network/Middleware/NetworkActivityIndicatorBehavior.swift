//
//  NetworkActivityIndicatorBehavior.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

class ActivityIndicatorState {
    
    static let shared = ActivityIndicatorState()
    
    var counter = 0 {
        didSet {
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = self.counter != 0
            }
        }
    }
}

class NetworkActivityIndicatorBehavior: RequestBehavior {
    
    let state = ActivityIndicatorState.shared
    
    func beforeSend() {
        state.counter += 1
    }
    
    func afterSuccess() {
        state.counter -= 1
    }
    
    func afterError(_ error: RequestError) {
        state.counter -= 1
    }
}
