//
//  TextFieldViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 21/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

protocol TextFieldViewModel {
    var value: BehaviorRelay<String> {  get }
    var isValid: Observable<Bool> { get }
    
    var title: String { get}
    var errorMessage: String { get }
}

//MARK: -
protocol SecureFieldViewModel {
    var isSecureTextEntry: Bool { get }
}
