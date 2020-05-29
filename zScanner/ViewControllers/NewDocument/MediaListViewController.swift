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
    func upload(_ fields: [[FormField]])
    func reeditMedia(media: Media)
    func createNewMedia()
    func deleteDocument()
}

class MediaListViewController: BaseViewController {
    
    // MARK: Instance part
    unowned let coordinator: MediaListCoordinator
    let viewModel: MediaListViewModel
    
    init(viewModel: MediaListViewModel, coordinator: MediaListCoordinator) {
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
    
    @objc private func takeNewPicture() {
        coordinator.createNewMedia()
    }
    
    private func setupBindings() {
        viewModel.mediaArray
            .map({ !$0.isEmpty })
            .bind(to: sendButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        viewModel.isValid
            .bind(to: sendButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        sendButton.rx.tap
            .subscribe(onNext: { [unowned self] in
                self.coordinator.upload(self.viewModel.fields)
            })
            .disposed(by: disposeBag)
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
        viewModel.addDateTimePickerPlaceholder(index: newIndex, section: indexPath.section, for: date)
        let index = IndexPath(row: newIndex, section: indexPath.section)
        tableView.insertRows(at: [index], with: .fade)
        tableView.endUpdates()
        
        pickerIndexPath = index
    }
    
    private func hideDateTimePicker(section: Int) {
        tableView.beginUpdates()
        if let index = pickerIndexPath {
            viewModel.removeDateTimePickerPlaceholder(section: section)
            tableView.deleteRows(at: [index], with: .fade)
        }
        tableView.endUpdates()
        
        pickerIndexPath = nil
    }
    
    private func setupView() {
        navigationItem.title = viewModel.folderName
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(sendButton)
        sendButton.snp.makeConstraints { make in
            make.right.bottom.left.equalTo(safeArea).inset(20)
            make.height.equalTo(44)
        }

        view.addSubview(gradientView)
        gradientView.snp.makeConstraints { make in
            make.top.equalTo(safeArea.snp.bottom).offset(-80)
            make.right.bottom.left.equalToSuperview()
        }
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerCell(FormFieldTableViewCell.self)
        tableView.registerCell(TextInputTableViewCell.self)
        tableView.registerCell(DateTimePickerTableViewCell.self)
        tableView.registerCell(SegmentControlTableViewCell.self)
        tableView.registerCell(CollectionViewTableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    private lazy var sendButton: PrimaryButton = {
        let button = PrimaryButton()
        button.setTitle("newDocumentPhotos.button.title".localized, for: .normal)
        button.dropShadow()
        return button
    }()
    
    private lazy var gradientView = GradientView()
}

// MARK: - UITableViewDataSource implementation
extension MediaListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.fields.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.fields[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = viewModel.fields[indexPath.section][indexPath.row]
        
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
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell
        case let segmentControl as SegmentControlField:
            let cell = tableView.dequeueCell(SegmentControlTableViewCell.self)
            cell.setup(with: segmentControl)
            cell.selectionStyle = .none
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell
        case let collectionView as CollectionViewField:
            let cell = tableView.dequeueCell(CollectionViewTableViewCell.self)
            cell.setup(with: collectionView, viewModel: viewModel, delegate: self)
            cell.selectionStyle = .none
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
            return cell
        default:
            return UITableViewCell()
        }
    }
}

// MARK: - UITableViewDelegate implementation
extension MediaListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = viewModel.fields[indexPath.section][indexPath.row]
        
        // Hide picker if user select different cell
        if self.pickerIndexPath != nil && !(item is DateTimePickerField) {
            self.hideDateTimePicker(section: indexPath.section)
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
                hideDateTimePicker(section: indexPath.section)
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

// MARK: - CollectionViewCellDelegate implementation
extension MediaListViewController: CollectionViewCellDelegate {
    func reeditMedium(media: Media) {
        coordinator.reeditMedia(media: media)
    }
    
    func createNewMedium() {
        coordinator.createNewMedia()
    }
}
