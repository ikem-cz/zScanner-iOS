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
        
        updateTableView()
        setupBindings()
    }
    
    override var leftBarButtonItems: [UIBarButtonItem] {
        return [
            hambugerButton
        ]
    }
    
    // MARK: Interface
    func insertNewDocument(document: DocumentViewModel) {
        dismissBottomSheet()
        viewModel.insertNewDocument(document)
    }
    
    // MARK: Helpers
    private let disposeBag = DisposeBag()
    
    func updateViewModel() {
        viewModel.updateFolders()
    }
    
    private func setupBindings() {
        viewModel.documentModesState
            .observeOn(MainScheduler.instance )
            .subscribe(onNext: { [weak self] state in
                switch state {
                case .error:
                    self?.showDocumentTypesErrorAlert()
                default:
                    break
                }
            }).disposed(by: disposeBag)
        
        Observable.combineLatest([
                viewModel.activeFolders,
                viewModel.sentFolders
            ])
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.updateTableView()
            })
            .disposed(by: disposeBag)
    }
    
    func showDocumentTypesErrorAlert() {
        let alert = UIAlertController(title: "dialog.requestError.title".localized, message: "dialog.requestError.noDocumentTypes".localized, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "dialog.requestError.retry".localized, style: .default, handler: { _ in self.viewModel.fetchDocumentTypes() }))
        
        self.present(alert, animated: true)
    }
    
    @objc private func openMenu() {
        coordinator.openMenu()
    }
    
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
    
    private func updateTableView() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, FolderViewModel>()
        
        let count = viewModel.folders.count
        tableView.backgroundView?.isHidden = count > 0
        
        let active = viewModel.activeFolders.value
        if !active.isEmpty {
            snapshot.appendSections([.active])
            snapshot.appendItems(active, toSection: .active)
        }
        
        let sent = viewModel.sentFolders.value
        if !sent.isEmpty {
            snapshot.appendSections([.sent])
            snapshot.appendItems(sent, toSection: .sent)
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
        tableView.registerCell(FolderStatusTableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        tableView.delegate = self
        return tableView
    }()
    
    lazy var dataSource: UITableViewDiffableDataSource<Section, FolderViewModel> = {
        UITableViewDiffableDataSource<Section, FolderViewModel>(
            tableView: self.tableView,
            cellProvider: {  (tableView, indexPath, folder) in
                let cell = tableView.dequeueCell(FolderStatusTableViewCell.self)
                cell.setup(with: folder, delegate: self)
                return cell
            }
        )
    }()
    
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
extension FoldersListViewController: FolderViewDelegate {
    func createNewDocumentToFolder(folderViewModel: FolderViewModel) {
        let folderSelection = FolderSelection(folder: folderViewModel.folder, searchMode: .history)
        coordinator.createNewDocument(with: folderSelection)
    }
}
