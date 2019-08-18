//
//  NewDocumentPhotosViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 14/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift

protocol NewDocumentPhotosCoordinator: BaseCoordinator {
    func savePhotos(_ photos: [UIImage])
    func showNextStep()
}

// MARK: -
class NewDocumentPhotosViewController: BaseViewController {
    
    // MARK: Instance part
    private unowned let coordinator: NewDocumentPhotosCoordinator
    private let viewModel: NewDocumentPhotosViewModel
    
    init(viewModel: NewDocumentPhotosViewModel, coordinator: NewDocumentPhotosCoordinator) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        
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
    
    override var rightBarButtonItems: [UIBarButtonItem] {
        return [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(takeNewPicture))
        ]
    }
    
    // MARK: Helpers
    let disposeBag = DisposeBag()
    
    @objc private func takeNewPicture() {
        showActionSheet()
    }
    
    private func showActionSheet() {
        let alert = UIAlertController(title: "newDocumentPhotos.actioSheet.title".localized, message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "newDocumentPhotos.actioSheet.cameraAction".localized, style: .default, handler: { _ in
                self.openCamera()
            }))
        }

        alert.addAction(UIAlertAction(title: "newDocumentPhotos.actioSheet.galleryAction".localized, style: .default, handler: { _ in
            self.openGallery()
        }))

        alert.addAction(UIAlertAction.init(title: "newDocumentPhotos.actioSheet.cancel".localized, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        return picker
    }()
    
    private func openCamera() {
       imagePicker.sourceType = .camera
       present(imagePicker, animated: true, completion: nil)
    }
    
    private func openGallery() {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    private func setupBindings() {
        viewModel.pictures
            .bind(
                to: collectionView.rx.items(cellIdentifier: "PhotoSelectorCollectionViewCell", cellType: PhotoSelectorCollectionViewCell.self),
                curriedArgument: { [unowned self] (row, image, cell) in
                    cell.setup(with: image, delegate: self)
                }
            )
            .disposed(by: disposeBag)
        
        viewModel.pictures
            .map({ !$0.isEmpty })
            .bind(to: continueButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        continueButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                self.coordinator.savePhotos(self.viewModel.pictures.value)
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

// MARK: - UIImagePickerControllerDelegate implementation
extension NewDocumentPhotosViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            viewModel.addImage(pickedImage)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - PhotoSelectorCellDelegate implementation
extension NewDocumentPhotosViewController: PhotoSelectorCellDelegate {
    func delete(image: UIImage) {
        viewModel.removeImage(image)
    }
}
