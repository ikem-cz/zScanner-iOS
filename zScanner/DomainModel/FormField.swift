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
        return selected.map({ $0?.title ?? "form.listPicker.unselected".localized }).asObservable()
    }
    var isValid: Observable<Bool> {
        return selected.map({ $0 != nil }).asObservable()
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
        return text.asObservable()
    }
    var isValid: Observable<Bool> {
        return text.map({ self.validator($0) }).asObservable()
    }
    
    let text = BehaviorRelay<String>(value: "")
    let validator: (String) -> Bool
    
    init(title: String, validator: @escaping (String) -> Bool) {
        self.title = title
        self.validator = validator
    }
}

// MARK: -
protocol SegmentItem {
    var title: String { get }
}

// MARK: -
class SegmentPickerField<T: SegmentItem>: FormField {
    var title: String = ""
    
    var value: Observable<String> {
        return selected.map({
            $0?.title ?? "form.segmentControl.unselected".localized
        }).asObservable()
    }
    var isValid: Observable<Bool> {
        return selected.map({ $0 != nil }).asObservable()
    }
    
    var values: [T]
    let selected = BehaviorRelay<T?>(value: nil)
    
    init(values: [T]) {
        self.values = values
    }
}

// MARK: -
class CollectionViewField: FormField {
    var title: String = ""

    var value: Observable<String> {
        return picturesCount.map({ _ in "" }).asObservable()
    }
    var isValid: Observable<Bool> {
        return picturesCount.map({ $0 > 0 }).asObservable()
    }
    
    let picturesCount = BehaviorRelay<Int>(value: 0)
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
            $0?.dateTimeString ?? "form.listPicker.unselected".localized
        }).asObservable()
    }
    
    var isValid: Observable<Bool> {
        date.map({ self.validator($0) }).asObservable()
    }
    
    let date = BehaviorRelay<Date?>(value: nil)
    let validator: (Date?) -> Bool
    
    init(title: String, setDate: Bool = false, validator: @escaping (Date?) -> Bool) {
        self.title = title
        self.validator = validator
        
        if setDate { date.accept(Date()) }
    }
}

// MARK: -
class DateTimePickerPlaceholder: FormField {
    var title = ""
    var value = Observable<String>.empty()
    var isValid = Observable<Bool>.just(true)
    
    let date: DateTimePickerField
    
    init(for date: DateTimePickerField) {
        self.date = date
    }
}

// MARK: -
class ConfirmButton: FormField {
    var title: String = "form.confirmButton.title".localized
    var value: Observable<String> = .just("")
    var isValid: Observable<Bool> = .just(true)
}
