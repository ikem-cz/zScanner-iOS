//
//  SegmentControlTableViewCell.swift
//  zScanner
//
//  Created by Jan Provazník on 28/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift

class SegmentControlTableViewCell: UITableViewCell {

     // MARK: Instance part
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Interface
    func setup(with field: SegmentControlField) {
        segmentControl
            .rx
            .selectedSegmentIndex
            .subscribe(onNext: { field.segmentSelected.accept($0) })
            .disposed(by: disposeBag)
    }
    
    // MARK: Helpers
    private var disposeBag = DisposeBag()
    
    private func setupView() {
        contentView.addSubview(segmentControl)
        segmentControl.snp.makeConstraints { make in
            make.edges.equalTo(contentView.snp.margins)
        }
    }
    
    private lazy var segmentControl: UISegmentedControl = {
        let segmentControl = UISegmentedControl()
        segmentControl.insertSegment(withTitle: "documentMode.doc.name".localized, at: 0, animated: true)
        segmentControl.insertSegment(withTitle: "documentMode.exam.name".localized, at: 1, animated: true)
        return segmentControl
    }()
}
