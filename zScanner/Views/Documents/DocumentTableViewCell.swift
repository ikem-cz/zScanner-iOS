//
//  DocumentTableViewCell.swift
//  zScanner
//
//  Created by Jakub Skořepa on 21/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift

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
        disposeBag = DisposeBag()
    }
    
    //MARK: Interface
    func setup(with model: DocumentViewModel) {
        // Make sure the label will keep the space even when empty while respecting the dynamic font size
        titleLabel.text = String(format: "%@ %@", model.document.folder.externalId, model.document.folder.name)
        detailLabel.text = [
            model.document.type.mode.title,
            model.document.type.name,
            String(format: "document.documentCell.numberOfPagesFormat".localized, model.document.pages.count),
        ]
        .filter({ !$0.isEmpty })
        .joined(separator: " - ")
        
        model.documentUploadStatus
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                switch status {
                case .awaitingInteraction:
                    self?.successImageView.isHidden = true
                case .progress(let percentage):
                    self?.loadingCircle.progressValue(is: percentage)
                    self?.successImageView.isHidden = true
                case .success:
                    self?.successImageView.isHidden = false
                case .failed:
                    self?.successImageView.isHidden = true
                    // TODO: Handle error
                }
            }).disposed(by: disposeBag)
    }
    
    //MARK: Helpers
    private var disposeBag = DisposeBag()
    
    private func setupView() {
        selectionStyle = .none
        
        preservesSuperviewLayoutMargins = true
        contentView.preservesSuperviewLayoutMargins = true
        
        contentView.addSubview(textContainer)
        textContainer.snp.makeConstraints { make in
            make.top.equalTo(contentView.snp.topMargin)
            make.bottom.equalTo(contentView.snp.bottomMargin)
            make.left.equalTo(contentView.snp.leftMargin)
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
        
        contentView.addSubview(loadingContainer)
        loadingContainer.snp.makeConstraints { make in
            make.right.equalTo(contentView.snp.rightMargin)
            make.left.equalTo(textContainer.snp.right).offset(8)
            make.width.height.equalTo(30)
            make.centerY.equalToSuperview()
        }
        
        loadingContainer.addSubview(loadingCircle)
        loadingCircle.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        loadingContainer.addSubview(successImageView)
        successImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
        label.numberOfLines = 0
        return label
    }()
    
    private var loadingCircle = LoadingCircle()
    
    private var successImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.image = #imageLiteral(resourceName: "checkmark")
        return image
    }()
    
    private var textContainer = UIView()
    
    private var loadingContainer = UIView()
}
