//
//  FormField.swift
//  zScanner
//
//  Created by Jakub Skořepa on 04/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

protocol FormField {
    var title: String { get }
    var value: Observable<String> { get }
    var isValid: Observable<Bool> { get }
}

// MARK: -
protocol ListItem {
    var title: String { get }
}

// MARK: -
class ListPickerField<T: ListItem>: FormField {
    
    var title: String
    var value: Observable<String> {
        selected.map({ $0?.title ?? "form.listPicker.unselected".localized }).asObservable()
    }
    var isValid: Observable<Bool> {
        selected.map({ $0 != nil }).asObservable()
    }
    
    var list: [T]
    let selected = BehaviorRelay<T?>(value: nil)
        
    init(title: String, list: [T]) {
        self.title = title
        self.list = list
    }
}

// MARK: -
class TextInputField: FormField {

    var title: String
    var value: Observable<String> {
        text.asObservable()
    }
    var isValid: Observable<Bool> {
        text.map({ self.validator($0) }).asObservable()
    }
    
    let text = BehaviorRelay<String>(value: "")
    let validator: (String) -> Bool
    
    init(title: String, validator: @escaping (String) -> Bool) {
        self.title = title
        self.validator = validator
    }
}

// MARK: -
class ProtectedTextInputField: TextInputField {

    var protected = BehaviorRelay<Bool>(value: true)
}

// MARK: -
class DateTimePickerField: FormField {
    var title: String
    var value: Observable<String> {
        date.map({
            guard let date = $0 else { return "form.listPicker.unselected".localized }
            return self.formatter.string(from: date)
        }).asObservable()
    }
    
    var isValid: Observable<Bool> {
        date.map({ self.validator($0) }).asObservable()
    }
    
    let date = BehaviorRelay<Date?>(value: Date())
    let formatter: DateFormatter
    let validator: (Date?) -> Bool
    
    init(title: String, formatter: DateFormatter, validator: @escaping (Date?) -> Bool) {
        self.title = title
        self.formatter = formatter
        self.validator = validator
    }
}
