//
//  UsernameViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 21/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

struct UsernameViewModel: TextFieldViewModel {
    
    let value: BehaviorRelay<String> = BehaviorRelay(value: "")
    let isValid: Observable<Bool>
    
    let title = "USERNAME_TITLE".localized
    let errorMessage = "USERNAME_ERROR_MESSAGE".localized
    
    init() {
        isValid = value.asObservable().map({ return !$0.isEmpty })
    }
}
