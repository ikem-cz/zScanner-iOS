//
//  NewDocumentPhotosViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 14/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

class NewDocumentPhotosViewModel {
    
    // MARK: Instance part
    init() {}
    
    // MARK: Interface
    let pictures = BehaviorRelay<[UIImage]>(value: [])
    
    func addImage(_ image: UIImage) {
        var newArray = pictures.value
        newArray.append(image)
        pictures.accept(newArray)
    }
    
    func removeImage(_ image: UIImage) {
        var newArray = pictures.value
        _ = newArray.remove(image)
        pictures.accept(newArray)
    }
}
