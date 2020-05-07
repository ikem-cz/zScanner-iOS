//
//  CameraViewModel.swift
//  zScanner
//
//  Created by Jan Provazník on 07/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

class CameraViewModel {
    
    // MARK: Instance part
    let currentMode: BehaviorRelay<MediaType>
    
    let folderName: String
    let mediaSourceTypes: [MediaType]

    init(initialMode currentMode: MediaType, folderName: String, mediaSourceTypes: [MediaType]) {
        self.currentMode = BehaviorRelay<MediaType>(value: currentMode)
        self.folderName = folderName
        self.mediaSourceTypes = mediaSourceTypes
    }
    
    func newModeSelected(with mode: MediaType) {
        currentMode.accept(mode)
    }
    
}
