//
//  PageDomainModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 08/09/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

struct PageDomainModel: Equatable {
    var id: String
    var index: Int
    var correlationId: String
    var relativePath: String
    
    var image: UIImage {
        get {
            let absoluteUrl = URL(documentsWith: relativePath)
            return UIImage(data: try! Data(contentsOf: absoluteUrl))!
        }
        set {
            // Create folder for document
            let folderPath = correlationId
            let absolutePath = URL.documentsPath + folderPath
            
            if !FileManager.default.fileExists(atPath: absolutePath) {
                try! FileManager.default.createDirectory(atPath: absolutePath, withIntermediateDirectories: false, attributes: nil)
            }
            
            // Convert image to data and store to folder
            let data = newValue.jpegData(compressionQuality: 0.8)!
            let filePath = folderPath + id + ".jpg"
            let absoluteUrl = URL(documentsWith: filePath)
            try! data.write(to: absoluteUrl)
            
            self.relativePath = filePath
        }
    }
}

extension PageDomainModel {
    init(image: UIImage, index: Int, correlationId: String) {
        self.init(id: UUID().uuidString, index: index, correlationId: correlationId, relativePath: "")
        self.image = image
    }
}
