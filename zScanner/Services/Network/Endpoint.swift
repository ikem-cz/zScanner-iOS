//
//  Endpoint.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

protocol Endpoint {
    var url: String { get }
    var rawValue: String { get }
}
