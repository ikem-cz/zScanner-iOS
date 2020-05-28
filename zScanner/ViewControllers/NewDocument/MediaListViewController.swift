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
    func showSelector<T: ListItem>(for list: ListPickerField<T>)
    func upload(_ fields: [FormField])
    func reeditMedia(media: Media)
    func createNewMedia()
    func deleteDocument()
}

class MediaListViewController: BaseViewController {
    
    // MARK: Instance part
    unowned let coordinator: MediaListCoordinator
    let viewModel: NewDocumentMediaViewModel
    
    init(viewModel: NewDocumentMediaViewModel, coordinator: MediaListCoordinator) {
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
    
    override var rightBarButtonItems: [UIBarButtonItem] {
        return [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(takeNewPicture))
        ]
    }
    
    // MARK: Helpers
    let disposeBag = DisposeBag()
    
    @objc private func takeNewPicture() {
        coordinator.createNewMedia()
    }
    
    private func setupBindings() {
        collectionView
            .rx
            .itemSelected
            .subscribe(onNext: { indexPath in
                if let cell = self.collectionView.cellForItem(at: indexPath) as? PhotoSelectorCollectionViewCell {
                    guard let media = cell.element else { return }
                    self.coordinator.reeditMedia(media: media)
                }
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
        
        continueButton.rx.tap.do(onNext: { [unowned self] in
            self.tableView.visibleCells.forEach({ ($0 as? TextInputTableViewCell)?.enableSelection() })
            if self.pickerIndexPath != nil {
                self.hideDateTimePicker()
            }
        })
        .subscribe(onNext: { [unowned self] in
            self.coordinator.upload(self.viewModel.fields)
        }).disposed(by: disposeBag)
    }
    
    @objc func deleteDocument() {
        let alert = UIAlertController(title: "newDocument.popAlert.title".localized, message: "newDocument.popAlert.message".localized, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "newDocument.popAlert.confirm".localized, style: .default, handler: { _ in self.coordinator.deleteDocument() }))
        alert.addAction(UIAlertAction(title: "newDocument.popAlert.cancel".localized, style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    private var pickerIndexPath: IndexPath?
    
    private func showDateTimePicker(for indexPath: IndexPath, date: DateTimePickerField) {
        tableView.beginUpdates()
        let newIndex = indexPath.row + 1
        viewModel.addDateTimePickerPlaceholder(at: newIndex, for: date)
        let index = IndexPath(row: newIndex, section: indexPath.section)
        tableView.insertRows(at: [index], with: .fade)
        tableView.endUpdates()
        
        pickerIndexPath = index
    }
    
    private func hideDateTimePicker() {
        tableView.beginUpdates()
        if let index = pickerIndexPath {
            viewModel.removeDateTimePickerPlaceholder()
            tableView.deleteRows(at: [index], with: .fade)
        }
        tableView.endUpdates()
        
        pickerIndexPath = nil
    }
    
    private func setupView() {
        navigationItem.title = "newDocumentPhotos.screen.title".localized
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(continueButton)
        continueButton.snp.makeConstraints { make in
            make.right.bottom.left.equalTo(safeArea).inset(20)
            make.height.equalTo(44)
        }
//        view.addSubview(deleteButton)
//        deleteButton.snp.makeConstraints { make in
//            make.top.equalTo(safeArea)
//            make.leading.trailing.equalToSuperview().inset(20)
//            make.height.equalTo(30)
//        }
//
//        view.addSubview(tableView)
//        tableView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//        view.addSubview(collectionView)
//        collectionView.snp.makeConstraints { make in
//            make.top.equalTo(deleteButton.snp.bottom)
//            make.leading.trailing.bottom.equalToSuperview()
//        }
        
//        view.addSubview(gradientView)
//        gradientView.snp.makeConstraints { make in
//            make.top.equalTo(safeArea.snp.bottom).offset(-80)
//            make.right.bottom.left.equalToSuperview()
//        }
//
//        view.addSubview(continueButton)
//        continueButton.snp.makeConstraints { make in
//            make.right.bottom.left.equalTo(safeArea).inset(20)
//            make.height.equalTo(44)
//        }
//
//        collectionView.backgroundView = emptyView
//
//        emptyView.addSubview(emptyViewLabel)
//        emptyViewLabel.snp.makeConstraints { make in
//            make.width.equalToSuperview().multipliedBy(0.75)
//            make.centerX.equalToSuperview()
//            make.top.greaterThanOrEqualTo(collectionView.safeAreaLayoutGuide.snp.top)
//            make.centerY.equalToSuperview().multipliedBy(0.666).priority(900)
//        }
    }
    
    private lazy var scrollView = UIScrollView()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerCell(FormFieldTableViewCell.self)
        tableView.registerCell(TextInputTableViewCell.self)
        tableView.registerCell(DateTimePickerTableViewCell.self)
        tableView.registerCell(SegmentControlTableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.tableFooterView = UIView()
        return tableView
    }()

    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .white
        collectionView.register(PhotoSelectorCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoSelectorCollectionViewCell")
        collectionView.register(AddNewMediaCollectionViewCell.self, forCellWithReuseIdentifier: "AddNewMediaCollectionViewCell")
        collectionView.dataSource = self
        return collectionView
    }()
    
    private lazy var continueButton: PrimaryButton = {
        let button = PrimaryButton()
        button.setTitle("newDocumentPhotos.button.title".localized, for: .normal)
        button.dropShadow()
        return button
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton()
        let attributedString = NSAttributedString(string: "newDocumentPhotos.deleteDocument.title".localized,
                                                  attributes: [
                                                       .underlineStyle: NSUnderlineStyle.single.rawValue,
                                                       .foregroundColor: UIColor.red,
                                                       .font: UIFont.footnote
                                                  ])
        button.setAttributedTitle(attributedString, for: .normal)
        button.addTarget(self, action: #selector(deleteDocument), for: .touchUpInside)
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

// MARK: - UICollectionViewDataSource implementation
extension MediaListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.mediaArray.value.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == viewModel.mediaArray.value.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddNewMediaCollectionViewCell", for: indexPath) as! AddNewMediaCollectionViewCell
            cell.setup(delegate: self)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoSelectorCollectionViewCell", for: indexPath) as! PhotoSelectorCollectionViewCell
            let media = viewModel.mediaArray.value[indexPath.row]
            cell.setup(with: media, delegate: self)
            return cell
        }
    }
}

// MARK: - UITableViewDataSource implementation
extension MediaListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.fields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = viewModel.fields[indexPath.row]
        
        switch item {
        case let list as ListPickerField<DocumentTypeDomainModel>:
            let cell = tableView.dequeueCell(FormFieldTableViewCell.self)
            cell.setup(with: list)
            return cell
        case let text as TextInputField:
            let cell = tableView.dequeueCell(TextInputTableViewCell.self)
            cell.setup(with: text)
            return cell
        case let date as DateTimePickerField:
            let cell = tableView.dequeueCell(FormFieldTableViewCell.self)
            cell.setup(with: date)
            return cell
        case let datePicker as DateTimePickerPlaceholder:
            let cell = tableView.dequeueCell(DateTimePickerTableViewCell.self)
            cell.setup(with: datePicker)
            return cell
        case _ as SegmentControlField:
            let cell = tableView.dequeueCell(SegmentControlTableViewCell.self)
            return cell
        default:
            return UITableViewCell()
        }
    }
}

// MARK: - UITableViewDelegate implementation
extension MediaListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = viewModel.fields[indexPath.row]
        
        // Hide picker if user select different cell
        if self.pickerIndexPath != nil && !(item is DateTimePickerField) {
            self.hideDateTimePicker()
        }
        
        // Remove focus from textField is user select different cell
        tableView.visibleCells.forEach({ ($0 as? TextInputTableViewCell)?.enableSelection() })
        
        switch item {
        case let list as ListPickerField<DocumentTypeDomainModel>:
            coordinator.showSelector(for: list)
        case let date as DateTimePickerField:
            if pickerIndexPath == nil {
                showDateTimePicker(for: indexPath, date: date)
            } else {
                hideDateTimePicker()
            }
        case is TextInputField:
            if let cell = tableView.cellForRow(at: indexPath) as? TextInputTableViewCell {
                cell.enableTextEdit()
            }
        default:
            break
        }
    }
}


// MARK: - PhotoSelectorCellDelegate implementation
extension MediaListViewController: PhotoSelectorCellDelegate {
    func delete(media: Media) {
        viewModel.removeMedia(media)
    }
}

// MARK: - AddNewMediaCellDelegate implementation
extension MediaListViewController: AddNewMediaCellDelegate {
    func createNewMedia() {
        coordinator.createNewMedium()
    }
}
