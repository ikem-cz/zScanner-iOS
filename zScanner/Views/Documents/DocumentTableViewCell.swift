//
//  DocumentTableViewCell.swift
//  zScanner
//
//  Created by Jakub Skořepa on 21/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

class DocumentTableViewCell: UITableViewCell {
    
    //MARK: Instance part
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Lifecycle
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = nil
        detailLabel.text = nil
    }
    
    //MARK: Interface
    func setup(with document: DocumentViewModel) {
        titleLabel.text = document.document.type.title
        detailLabel.text = document.document.notes
    }
    
    //MARK: Helpers
    private func setupView() {
        selectionStyle = .none
        
        preservesSuperviewLayoutMargins = true
        contentView.preservesSuperviewLayoutMargins = true
        
        contentView.addSubview(textContainer)
        textContainer.snp.makeConstraints { make in
            make.edges.equalTo(contentView.snp.margins)
        }
        
        textContainer.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.right.left.equalToSuperview()
        }
        
        textContainer.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.right.left.bottom.equalToSuperview()
        }
    }
    
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .body
        label.textColor = .black
        return label
    }()
    
    private var detailLabel: UILabel = {
        let label = UILabel()
        label.font = .footnote
        label.textColor = UIColor.black.withAlphaComponent(0.7)
        return label
    }()
    
    private var textContainer: UIView = UIView()
}
