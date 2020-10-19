//
//  BodyImageNetworkModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 04/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

struct BodyImageNetworkModel: Decodable, ImageConverting {
    let image: UIImage
  
    init(image: UIImage) {
        self.image = image
    }
    
    init(from decoder: Decoder) throws {
        throw RequestError(.jsonParserError, message: "Trying to parse Image as JSON")
    }
}
