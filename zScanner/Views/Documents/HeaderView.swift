//
//  HeaderView.swift
//  zScanner
//
//  Created by Jan Provazník on 18/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

class HeaderView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        addSubview(label)
        label.snp.makeConstraints{ make in
            make.edges.equalToSuperview()
        }
    }
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.text = "documentMode.tableView.title".localized
        label.textColor = .black
        label.numberOfLines = 0
        label.font = .header
        return label
    }()

}
