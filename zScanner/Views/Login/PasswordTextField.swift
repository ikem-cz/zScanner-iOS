//
//  PasswordTextField.swift
//  zScanner
//
//  Created by Martin Georgiu on 16/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay

class PasswordTextField: UITextField {
   
    // MARK: Instance part
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var protected = BehaviorRelay<Bool>(value: true)
    
    lazy var passwordToggleButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(#imageLiteral(resourceName: "eyeClose"), for: .normal)
        button.setImage(#imageLiteral(resourceName: "eyeOpen"), for: .selected)
        return button
    }()
    
    // MARK: Helpers
    private let disposeBag = DisposeBag()

    private func setupView() {
        passwordToggleButton.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        
        self.rightView = passwordToggleButton
        self.rightViewMode = .always
        
        protected.subscribe(onNext: { [weak self] status in
            self?.passwordToggleButton.isSelected = !status
            self?.isSecureTextEntry = status
        }).disposed(by: disposeBag)
    }
    
    // By default, text inside UITextField automatically delete itself after going
    // from false to true in UITextField.isSecureTextEntry
    // Below is snippet to prevent that.
    override var isSecureTextEntry: Bool {
        didSet {
            if isFirstResponder {
                _ = becomeFirstResponder()
            }
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        
        var startPosition: UITextPosition?
        var endPosition: UITextPosition?
        
        // Remember the place where cursor was placed before switching secureTextEntry
        if let selectedRange = self.selectedTextRange {
            startPosition = selectedRange.start
            endPosition = selectedRange.end
        }

        let success = super.becomeFirstResponder()
        if isSecureTextEntry, let text = self.text {
            self.text?.removeAll()
            insertText(text)
        }
        
        // Put the cursor back
        if let startPosition = startPosition {
            self.selectedTextRange = self.textRange(from: startPosition, to: endPosition ?? startPosition)
        }
        
        return success
    }
}
