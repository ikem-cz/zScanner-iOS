//
//  NewDocumentTypeViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 01/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift

protocol NewDocumentTypeCoordinator: BaseCoordinator {
    func showSelector<T: ListItem>(for list: ListPickerField<T>)
    func saveFields(_ fields: [FormField])
}

// MARK: -
class NewDocumentTypeViewController: BaseViewController {
    
    // MARK: Instance part
    private unowned let coordinator: NewDocumentTypeCoordinator
    private let viewModel: NewDocumentTypeViewModel
    
    init(viewModel: NewDocumentTypeViewModel, coordinator: NewDocumentTypeCoordinator) {
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
    
    // MARK: Helpers
    private let disposeBag = DisposeBag()
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
    
    private func setupBindings() {
        viewModel.isValid
            .bind(to: continueButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        continueButton.rx.tap.do(onNext: { [unowned self] in
            self.tableView.visibleCells.forEach({ ($0 as? TextInputTableViewCell)?.enableSelection() })
            if self.pickerIndexPath != nil {
                self.hideDateTimePicker()
            }
        })
        .subscribe(onNext: { [unowned self] in
            self.coordinator.saveFields(self.viewModel.fields)
        }).disposed(by: disposeBag)
    }
    
    private func setupView() {
        navigationItem.title = "newDocumentType.screen.title".localized
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(continueButton)
        continueButton.snp.makeConstraints { make in
            make.right.bottom.left.equalTo(safeArea).inset(20)
            make.height.equalTo(44)
        }
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerCell(FormFieldTableViewCell.self)
        tableView.registerCell(TextInputTableViewCell.self)
        tableView.registerCell(DateTimePickerTableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    private lazy var continueButton: PrimaryButton = {
        let button = PrimaryButton()
        button.setTitle("newDocumentType.button.title".localized, for: .normal)
        return button
    }()
}

// MARK: - UITableViewDataSource implementation
extension NewDocumentTypeViewController: UITableViewDataSource {
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
        default:
            return UITableViewCell()
        }
    }
}

// MARK: - UITableViewDelegate implementation
extension NewDocumentTypeViewController: UITableViewDelegate {
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
