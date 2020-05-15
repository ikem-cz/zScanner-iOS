//
//  NewDocumentMediaSelectionViewController.swift
//  zScanner
//
//  Created by Jan Provazník on 12/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import MobileCoreServices

protocol MediaListCoordinator: BaseCoordinator {
    func upload()
    func reeditMedium(type: MediaType, url: URL)
}

class MediaListViewController: BaseViewController {
    
    // MARK: Instance part
    unowned let coordinator: MediaListCoordinator
    let viewModel: MediaViewModel
    
    init(viewModel: MediaViewModel, coordinator: MediaListCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        
        super.init(coordinator: coordinator)
    }
    
    // MARK: Lifecycle
    override func loadView() {
        super.loadView()
        
        setupView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBindings()
    }
    
    // MARK: Helpers
    let disposeBag = DisposeBag()
    
    private func setupBindings() {
        viewModel.mediaArray
            .bind(
                to: collectionView.rx.items(cellIdentifier: "PhotoSelectorCollectionViewCell", cellType: PhotoSelectorCollectionViewCell.self),
                curriedArgument: { [unowned self] (row, media, cell) in
                    cell.setup(with: media, delegate: self)
                }
            )
            .disposed(by: disposeBag)
        
        collectionView
            .rx
            .itemSelected
            .subscribe(onNext: { indexPath in
                let cell = self.collectionView.cellForItem(at: indexPath) as! PhotoSelectorCollectionViewCell
                guard let fileURL = cell.element?.key else { return }
                self.coordinator.reeditMedium(type: self.viewModel.mediaType, url: fileURL)
            }).disposed(by: disposeBag)
        
        viewModel.mediaArray
            .subscribe(onNext: { [weak self] pictures in
                self?.collectionView.backgroundView?.isHidden = pictures.count > 0
            })
            .disposed(by: disposeBag)
        
        viewModel.mediaArray
            .map({ !$0.isEmpty })
            .bind(to: continueButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        continueButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                self.coordinator.upload()
            })
            .disposed(by: disposeBag)
    }
    
    private func setupView() {
        navigationItem.title = "newDocumentPhotos.screen.title".localized

        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(gradientView)
        gradientView.snp.makeConstraints { make in
            make.top.equalTo(safeArea.snp.bottom).offset(-80)
            make.right.bottom.left.equalToSuperview()
        }
        
        view.addSubview(continueButton)
        continueButton.snp.makeConstraints { make in
            make.right.bottom.left.equalTo(safeArea).inset(20)
            make.height.equalTo(44)
        }
        
        collectionView.backgroundView = emptyView
        
        emptyView.addSubview(emptyViewLabel)
        emptyViewLabel.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.75)
            make.centerX.equalToSuperview()
            make.top.greaterThanOrEqualTo(collectionView.safeAreaLayoutGuide.snp.top)
            make.centerY.equalToSuperview().multipliedBy(0.666).priority(900)
        }
    }
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .white
        collectionView.register(PhotoSelectorCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoSelectorCollectionViewCell")
        return collectionView
    
    }()
    
    private lazy var continueButton: PrimaryButton = {
        let button = PrimaryButton()
        button.setTitle("newDocumentPhotos.button.title".localized, for: .normal)
        button.dropShadow()
        return button
    }()
    
    private lazy var emptyView = UIView()
    
    private lazy var emptyViewLabel: UILabel = {
        let label = UILabel()
        label.text = "newDocumentPhotos.emptyView.title".localized
        label.textColor = .black
        label.numberOfLines = 0
        label.font = .body
        label.textAlignment = .center
        return label
    }()
    
    private lazy var gradientView = GradientView()
    
    private let margin: CGFloat = 10
    private let numberofColumns: CGFloat = 2
    
    private var itemWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return (screenWidth - (numberofColumns + 1) * margin) / numberofColumns
    }
    
    private lazy var flowLayout: UICollectionViewLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = margin
        layout.minimumLineSpacing = margin
        layout.sectionInset = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        return layout
    }()
}

// MARK: - PhotoSelectorCellDelegate implementation
extension MediaListViewController: PhotoSelectorCellDelegate {
    func delete(fileURL: URL) {
        viewModel.removeMedia(fileURL)
    }
}
