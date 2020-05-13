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

protocol MediaCoordinator: BaseCoordinator {
    func saveMedia()
    func showNextStep()
}

class MediaViewController: BaseViewController {
    
    // MARK: Instance part
    unowned let coordinator: MediaCoordinator
    let viewModel: NewDocumentMediaViewModel
    
    init(viewModel: NewDocumentMediaViewModel, coordinator: MediaCoordinator) {
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
                curriedArgument: { [unowned self] (row, medium, cell) in
                    cell.setup(with: medium.value, delegate: self)
                }
            )
            .disposed(by: disposeBag)
        
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
                self.coordinator.saveMedia()
                self.coordinator.showNextStep()
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
extension NewDocumentMediaViewController: PhotoSelectorCellDelegate {
    func delete(image: UIImage) {
        guard let URLToDelete = self.viewModel.mediaArray.value.someKey(forValue: image) else { return }
        viewModel.removeMedia(URLToDelete)
    }
}
