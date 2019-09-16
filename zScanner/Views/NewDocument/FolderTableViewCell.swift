//
//  FolderTableViewCell.swift
//  zScanner
//
//  Created by Jakub Skořepa on 12/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

class FolderTableViewCell: UITableViewCell {
    
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
    }
    
    // MARK: Interface
    func setup(with folder: FolderDomainModel) {
        idLabel.text = folder.externalId
        nameLabel.text = folder.name
    }
    
    // MARK: Helpers
    private func setupView() {
        selectionStyle = .none
        
        contentView.addSubview(idLabel)
        idLabel.snp.makeConstraints { make in
            make.width.equalTo(14).priority(500)
            make.top.bottom.equalToSuperview().inset(13)
            make.left.equalToSuperview().inset(15)
        }
        
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(13)
            make.left.equalTo(idLabel.snp.right).offset(8)
            make.right.equalToSuperview().inset(15)
        }
    }
    
    private var idLabel: UILabel = {
        let label = UILabel()
        label.font = .body
        label.textColor = .black
        return label
    }()
   
    private var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .body
        label.textColor = .black
        return label
    }()
}
