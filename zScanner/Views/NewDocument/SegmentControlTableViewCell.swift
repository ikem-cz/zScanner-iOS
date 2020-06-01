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
    
    // MARK: Lifecycle
    override func prepareForReuse() {
        super.prepareForReuse()
        segmentedControl.removeAllSegments()
        disposeBag = DisposeBag()
    }
    
    // MARK: Interface
    func setup<T>(with segmentPicker: SegmentPickerField<T>) {
        segmentPicker.values.enumerated().forEach({
            segmentedControl.insertSegment(withTitle: $0.element.title, at: $0.offset, animated: false)
        })
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl
            .rx
            .selectedSegmentIndex
            .subscribe(onNext: { segmentPicker.selected.accept(segmentPicker.values[$0]) })
            .disposed(by: disposeBag)
    }
    
    // MARK: Helpers
    private var disposeBag = DisposeBag()
    
    private func setupView() {
        selectionStyle = .none
        
        preservesSuperviewLayoutMargins = true
        contentView.preservesSuperviewLayoutMargins = true
        
        contentView.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.edges.equalTo(contentView.snp.margins)
        }
    }
    
    private lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl()
        segmentedControl.selectedSegmentIndex = 0
        return segmentedControl
    }()
}
