//
//  DateTimePickerTableViewCell.swift
//  zScanner
//
//  Created by Jakub Skořepa on 05/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift

class DateTimePickerTableViewCell: UITableViewCell {
    
    // MARK: Instance part
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposeBag = DisposeBag()
    }
    
    // MARK: Interface
    func setup(with datePicker: DateTimePickerPlaceholder) {
        dateTimePicker.rx.value
            .bind(to: datePicker.date.date)
            .disposed(by: disposeBag)
    }
    
    // MARK: Helpers
    private var disposeBag = DisposeBag()
    
    private func setupView() {
        selectionStyle = .none
        
        preservesSuperviewLayoutMargins = true
        contentView.preservesSuperviewLayoutMargins = true
        
        contentView.addSubview(dateTimePicker)
        dateTimePicker.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private lazy var dateTimePicker: UIDatePicker = {
        let picker = UIDatePicker()
        let closest5 = Date().ceil(precision: 5 * 60)
        picker.minimumDate = closest5
        picker.date = closest5
        picker.datePickerMode = .dateAndTime
        picker.minuteInterval = 5
        return picker
    }()
}
