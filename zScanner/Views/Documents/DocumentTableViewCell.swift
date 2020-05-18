//
//  DocumentTableViewCell.swift
//  zScanner
//
//  Created by Jakub Skořepa on 21/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift

protocol DocumentViewDelegate {
    func handleError(_ error: RequestError)
}

class DocumentTableViewCell: UITableViewCell {
    
    //MARK: Instance part
    private var viewModel: DocumentViewModel?
    private var delegate: DocumentViewDelegate?
    
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
        
        viewModel = nil
        delegate = nil
        titleLabel.text = nil
        detailLabel.text = nil
        loadingCircle.isHidden = true
        loadingCircle.progressValue(is: 0, animated: false)
        successImageView.isHidden = true
        retryButton.isHidden = true
        
        disposeBag = DisposeBag()
    }
    
    //MARK: Interface
    func setup(with model: DocumentViewModel, delegate: DocumentViewDelegate) {
        self.viewModel = model
        self.delegate = delegate
        
        // Make sure the label will keep the space even when empty while respecting the dynamic font size
        titleLabel.text = String(format: "%@ %@", model.document.folder.externalId, model.document.folder.name)
        detailLabel.text = [
            model.document.type.mode.title,
            model.document.type.name,
            String(format: "document.documentCell.numberOfPagesFormat".localized, model.document.pages.count),
        ]
        .filter({ !$0.isEmpty })
        .joined(separator: " - ")
        
        let onCompleted: () -> Void = { [weak self] in
            self?.retryButton.isHidden = true
            
            // If not animating, skip trnasition animation
            if self?.loadingCircle.isHidden == true {
                self?.loadingCircle.isHidden = true
                self?.successImageView.isHidden = false
                return
            }
            
            self?.successImageView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            self?.successImageView.isHidden = false
            self?.successImageView.alpha = 0
            
            UIView.animate(withDuration: 0.5, animations: {
                self?.successImageView.alpha = 1
                self?.successImageView.transform = CGAffineTransform(scaleX: 1, y: 1)
                self?.loadingCircle.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                self?.loadingCircle.alpha = 0
            }, completion: { _ in
                self?.loadingCircle.isHidden = true
                self?.loadingCircle.alpha = 1
                self?.loadingCircle.transform = CGAffineTransform(scaleX: 1, y: 1)
            })
        }
        
        let onError: (Error?) -> Void = { [weak self] error in
            self?.loadingCircle.isHidden = true
            self?.successImageView.isHidden = true
            self?.retryButton.isHidden = false
            if let error = error as? RequestError {
                self?.delegate?.handleError(error)
            }
        }
        
        model.documentUploadStatus
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                switch status {
                case .awaitingInteraction:
                    self?.loadingCircle.isHidden = true
                    self?.successImageView.isHidden = true
                    self?.retryButton.isHidden = true
                case .progress(let percentage):
                    self?.loadingCircle.progressValue(is: percentage)
                    self?.loadingCircle.isHidden = false
                    self?.successImageView.isHidden = true
                    self?.retryButton.isHidden = true
                case .success:
                    onCompleted()
                case .failed(let error):
                    onError(error)
                }
            })
            .disposed(by: disposeBag)
        
        retryButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.viewModel?.reupload()
        })
        .disposed(by: disposeBag)
    }
    
    //MARK: Helpers
    private var disposeBag = DisposeBag()
    
    private func setupView() {
        selectionStyle = .none
        backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        
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
        
        titleLabel.setContentHuggingPriority(.init(rawValue: 251), for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.init(rawValue: 751), for: .vertical)
        
        textContainer.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.right.left.bottom.equalToSuperview()
        }
        
        contentView.addSubview(statusContainer)
        statusContainer.snp.makeConstraints { make in
            make.right.equalTo(contentView.snp.rightMargin)
            make.left.equalTo(textContainer.snp.right).offset(8)
            make.width.height.equalTo(30)
            make.centerY.equalToSuperview()
        }
        
        statusContainer.addSubview(loadingCircle)
        loadingCircle.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        statusContainer.addSubview(successImageView)
        successImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        statusContainer.addSubview(retryButton)
        retryButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func roundedCorners(corners: CACornerMask, radius : CGFloat) {
        clipsToBounds = true
        layer.cornerRadius = radius
        layer.maskedCorners = corners
        separatorInset = .zero
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
    
    private var retryButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "refresh"), for: .normal)
        return button
    }()
    
    private var textContainer = UIView()
    
    private var statusContainer = UIView()
}
