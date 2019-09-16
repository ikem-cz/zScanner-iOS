//
//  TextInputTableViewCell.swift
//  zScanner
//
//  Created by Jakub Skořepa on 05/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift

class TextInputTableViewCell: UITableViewCell {
    
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
        
        textField.placeholder = nil
        disposeBag = DisposeBag()
        
        enableSelection()
    }
    
    // MARK: Interface
    func setup(with textInput: TextInputField) {
        textField.placeholder = textInput.title
        textField.rx.text
                   .orEmpty
                   .bind(to: textInput.text)
                   .disposed(by: disposeBag)
        
        enableSelection()
    }
    
    func enableSelection() {
        textField.isUserInteractionEnabled = false
        textField.resignFirstResponder()
    }
    
    func enableTextEdit() {
        textField.isUserInteractionEnabled = true
        textField.becomeFirstResponder()
    }
    
    // MARK: Helpers
    private var disposeBag = DisposeBag()
    
    private func setupView() {
        selectionStyle = .none
        
        preservesSuperviewLayoutMargins = true
        contentView.preservesSuperviewLayoutMargins = true
        
        contentView.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.edges.equalTo(contentView.snp.margins)
        }
    }
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.font = .body
        return textField
    }()
}

// MARK: - UITextFieldDelegate implementation
extension TextInputTableViewCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        enableSelection()
    }
}
