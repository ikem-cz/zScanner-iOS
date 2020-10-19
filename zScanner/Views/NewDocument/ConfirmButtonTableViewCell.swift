//
//  ConfirmButtonTableViewCell.swift
//  zScanner
//
//  Created by Jakub Skořepa on 13/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift

class ConfirmButtonTableViewCell: UITableViewCell {
    
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
        
        button.setTitle(nil, for: .normal)
    }
    
    // MARK: Interface
    func setup(with button: ConfirmButton) {
        self.button.setTitle(button.title, for: .normal)
    }
    
    // MARK: Helpers
    private func setupView() {
        selectionStyle = .none
        backgroundColor = .clear
        
        preservesSuperviewLayoutMargins = true
        contentView.preservesSuperviewLayoutMargins = true
        
        contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalTo(contentView.snp.margins).inset(8)
        }
        button.isUserInteractionEnabled = false
    }
    
    private lazy var button = PrimaryButton()
}
