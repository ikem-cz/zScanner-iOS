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
    var url: URL
    var index: Int
    var correlationId: String
    
    var image: UIImage {
        get {
            return UIImage(data: try! Data(contentsOf: url))!
        }
        set {
            // Create folder for document
            let folderPath = documentsPath + "/" + correlationId
            if !FileManager.default.fileExists(atPath: folderPath) {
                try! FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: false, attributes: nil)
            }
            
            // Convert image to data and store to folder
            let data = newValue.jpegData(compressionQuality: 0.8)!
            let fileName = URL(fileURLWithPath: folderPath + "/\(index).jpg")
            try! data.write(to: fileName)
            
            self.url = fileName
        }
    }
    
    private var documentsPath: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
}

extension PageDomainModel {
    init(image: UIImage, index: Int, correlationId: String) {
        self.init(id: UUID().uuidString, url: URL(fileURLWithPath: ""), index: index, correlationId: correlationId)
        self.image = image
    }
}
