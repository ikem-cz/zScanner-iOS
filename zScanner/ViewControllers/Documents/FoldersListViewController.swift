//
//  DocumentsListViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 21/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift

protocol FoldersListCoordinator: BaseCoordinator {
    func createNewDocument(with folderSelection: FolderSelection)
    func openMenu()
}

class FoldersListViewController: BottomSheetPresenting, ErrorHandling {
    
    enum Section: CaseIterable {
        case active
        case sent
    }
    
    // MARK: Instance part
    private unowned let coordinator: FoldersListCoordinator
    private let viewModel: FoldersListViewModel

    init(viewModel: FoldersListViewModel, coordinator: FoldersListCoordinator) {
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
        
        viewModel.updateFolders()
        setupTableDataSource()
        setupBindings()
    }
    
    override var leftBarButtonItems: [UIBarButtonItem] {
        return [
            hambugerButton
        ]
    }
    
    override var rightBarButtonItems: [UIBarButtonItem] {
        return rightBarButtons
    }
    
    // MARK: Interface
    func insertNewDocument(document: DocumentViewModel) {
        viewModel.insertNewDocument(document)
    }
    
    // MARK: Helpers
    private let disposeBag = DisposeBag()
    private var rightBarButtons: [UIBarButtonItem] = [] {
        didSet {
            navigationItem.rightBarButtonItems = rightBarButtons
        }
    }
    
    private func setupBindings() {
        Observable.combineLatest([
                viewModel.activeFolders,
                viewModel.sentFolders
            ])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.updateTableDataSource()
            })
            .disposed(by: disposeBag)
    }
    
    @objc private func openMenu() {
        coordinator.openMenu()
    }
    
    var isActiveSectionPresenting = false
    
    private func setupView() {
        // Remove bottom line of navbar
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.equalTo(safeArea)
            // Set priority to 999 to silence console error for UIViewAlertForUnsatisfiableConstraints
            make.leading.trailing.equalToSuperview().inset(20).priority(999)
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.trailing.leading.equalToSuperview()
        }
        
        tableView.dataSource = dataSource
        tableView.backgroundView = emptyView
        
        emptyView.addSubview(emptyViewLabel)
        emptyViewLabel.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.75)
            make.centerX.equalToSuperview()
            make.top.greaterThanOrEqualTo(tableView.safeAreaLayoutGuide.snp.top)
            make.centerY.equalToSuperview().multipliedBy(0.666).priority(900)
        }
    }
    
    func setupTableDataSource() {
        var snapshot = dataSource.snapshot()
        
        let count = viewModel.folders.count
        tableView.backgroundView?.isHidden = count > 0
        
        snapshot.appendSections(Section.allCases)
        isActiveSectionPresenting = true
        snapshot.appendItems(viewModel.activeFolders.value, toSection: Section.active)
        snapshot.appendItems(viewModel.sentFolders.value, toSection: Section.sent)
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func updateTableDataSource() {
        var snapshot = dataSource.snapshot()
        
        let count = viewModel.folders.count
        tableView.backgroundView?.isHidden = count > 0
        
        if viewModel.activeFolders.value.count > 0 && !isActiveSectionPresenting {
            snapshot.appendSections([Section.active])
            snapshot.moveSection(Section.active, beforeSection: Section.sent)
            isActiveSectionPresenting = true
        }
        
        if !viewModel.activeFolders.value.isEmpty {
            snapshot.appendItems(viewModel.activeFolders.value, toSection: Section.active)
        }
        snapshot.appendItems(viewModel.sentFolders.value, toSection: Section.sent)
        
        if viewModel.activeFolders.value.isEmpty {
            snapshot.deleteSections([Section.active])
            isActiveSectionPresenting = false
        }
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private lazy var hambugerButton: UIBarButtonItem = {
        let hambugerButton = HambugerButton()
        let tap = UITapGestureRecognizer(target: self, action: #selector(openMenu))
        hambugerButton.addGestureRecognizer(tap)
        hambugerButton.isUserInteractionEnabled = true
        hambugerButton.setup(username: viewModel.login.username)
        return UIBarButtonItem(customView: hambugerButton)
    }()
    
    private lazy var headerView = HeaderView(frame: .zero)
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.registerCell(PatientTableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        tableView.delegate = self
        return tableView
    }()
    
    lazy var dataSource = makeDataSource()
    
    private lazy var emptyView = UIView()
    
    private lazy var emptyViewLabel: UILabel = {
        let label = UILabel()
        label.text = "document.emptyView.title".localized
        label.textColor = .black
        label.numberOfLines = 0
        label.font = .body
        label.textAlignment = .center
        return label
    }()
}

extension FoldersListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }
}

//MARK: - DocumentViewDelegate implementation
extension FoldersListViewController: FolderViewDelegate { }

private extension FoldersListViewController {
    func makeDataSource() -> UITableViewDiffableDataSource<Section, FolderViewModel> {
        return UITableViewDiffableDataSource<Section, FolderViewModel>(
            tableView: self.tableView,
            cellProvider: {  (tableView, indexPath, folder) in
                let cell = tableView.dequeueCell(PatientTableViewCell.self)
                cell.setup(with: folder, delegate: self)
                return cell
            }
        )
    }
}
