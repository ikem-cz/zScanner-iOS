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
        textLabel?.text = String(format: "%@   %@", folder.externalId, folder.name)
    }
    
    // MARK: Helpers
    private func setupView() {
        selectionStyle = .none
        
        textLabel?.font = UIFont.bodyMonospaced
    }
}
