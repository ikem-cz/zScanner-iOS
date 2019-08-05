//
//  FormFieldTableViewCell.swift
//  zScanner
//
//  Created by Jakub Skořepa on 05/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift

class FormFieldTableViewCell: UITableViewCell {
    
    // MARK: Instance part
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle
    override func prepareForReuse() {
        super.prepareForReuse()
        
        textLabel?.text = nil
        disposeBag = DisposeBag()
    }
    
    // MARK: Interface
    func setup(with formField: FormField) {
        textLabel?.text = formField.title
        
        formField.value.subscribe(onNext: {
            self.detailTextLabel?.text = $0
        }).disposed(by: disposeBag)
    }
    
    // MARK: Helpers
    private var disposeBag = DisposeBag()
    
    private func setupView() {
        accessoryType = .disclosureIndicator
        selectionStyle = .none
    }
}

