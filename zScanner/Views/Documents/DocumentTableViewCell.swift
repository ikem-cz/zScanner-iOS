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
    func setup(with document: DocumentViewModel) {
        // Make sure the label will keep the space even when empty while respecting the dynamic font size
        titleLabel.text = document.document.type.title.isEmpty ? " " : document.document.type.title
        detailLabel.text = document.document.notes.isEmpty ? " " : document.document.notes
        document.documentUploadStatus
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                switch status {
                case .awaitingInteraction:
                    self?.indicator.stopAnimating()
                    self?.successImageView.isHidden = true
                    self?.loadingCircle.isHidden = false
                case .progress(let percentage):
                    self?.loadingCircle.progressValue(is: percentage)
                    self?.indicator.startAnimating()
                    self?.successImageView.isHidden = true
                    self?.loadingCircle.isHidden = false
                case .success:
                    self?.indicator.stopAnimating()
                    self?.successImageView.isHidden = false
                    self?.loadingCircle.isHidden = true
                case .failed:
                    self?.indicator.stopAnimating()
                    self?.successImageView.isHidden = true
                    self?.loadingCircle.isHidden = false
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
            make.height.equalTo(21)
        }
        
        textContainer.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.right.left.bottom.equalToSuperview()
            make.height.equalTo(18)
        }
        
        contentView.addSubview(loadingContainer)
        loadingContainer.snp.makeConstraints { make in
            make.right.equalTo(contentView.snp.rightMargin)
            make.left.equalTo(textContainer.snp.right).offset(8)
            make.width.height.equalTo(30)
            make.centerY.equalToSuperview()
        }

        loadingContainer.addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
        return label
    }()
    
    private var indicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .gray)
        indicator.hidesWhenStopped = true
        return indicator
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
