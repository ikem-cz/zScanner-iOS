//
//  DocumentsListViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 21/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift

protocol DocumentsListCoordinator: BaseCoordinator {
    func createNewDocument()
    func openMenu()
}

class DocumentsListViewController: BaseViewController, ErrorHandling {
    
    enum Section: CaseIterable {
        case active
        case sent
    }
    
    // MARK: Instance part
    private unowned let coordinator: DocumentsListCoordinator
    private let viewModel: DocumentsListViewModel
        
    init(viewModel: DocumentsListViewModel, coordinator: DocumentsListCoordinator) {
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
        
        viewModel.updateDocuments()
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
        viewModel.documentModesState
            .asObserver()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] status in
                switch status {
                case .awaitingInteraction:
                    self.rightBarButtons = []
                case .loading:
                    self.rightBarButtons = [self.loadingItem]
                case .success:
                    self.rightBarButtons = [self.addButton]
                case .error(let error):
                    self.rightBarButtons = [self.reloadButton]
                    self.handleError(error, okCallback: nil) {
                        self.reloadDocumentTypes()
                    }
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.activeDocuments
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.updateTableDataSource()
            })
            .disposed(by: disposeBag)
        
        viewModel.sentDocuments
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.updateTableDataSource()
            })
            .disposed(by: disposeBag)
    }
    
    @objc private func newDocument() {
        coordinator.createNewDocument()
    }
    
    @objc private func openMenu() {
        coordinator.openMenu()
    }
    
    @objc private func reloadDocumentTypes() {
        viewModel.updateDocumentTypes()
    }
    
    var isActiveSectionPresenting = false
    
    private func setupView() {
        // Remove bottom line of navbar
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(safeArea)
            make.bottom.trailing.leading.equalToSuperview()
        }
        
        tableView.dataSource = dataSource
        tableView.backgroundView = emptyView
        tableView.tableHeaderView = headerView
        
        if let header = tableView.tableHeaderView {
            let newSize = header.systemLayoutSizeFitting(CGSize(width: tableView.bounds.width, height: 0))
            header.frame.size.height = newSize.height + 20
        }
        
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
        
        let count = viewModel.documents.count
        tableView.backgroundView?.isHidden = count > 0
        
        snapshot.appendSections(Section.allCases)
        isActiveSectionPresenting = true
        snapshot.appendItems(viewModel.activeDocuments.value, toSection: Section.active)
        snapshot.appendItems(viewModel.sentDocuments.value, toSection: Section.sent)
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func updateTableDataSource() {
        var snapshot = dataSource.snapshot()
        
        let count = viewModel.documents.count
        tableView.backgroundView?.isHidden = count > 0
        
        if viewModel.activeDocuments.value.count > 0 && !isActiveSectionPresenting {
            snapshot.appendSections([Section.active])
            snapshot.moveSection(Section.active, beforeSection: Section.sent)
            isActiveSectionPresenting = true
        }
        
        if !viewModel.activeDocuments.value.isEmpty {
            snapshot.appendItems(viewModel.activeDocuments.value, toSection: Section.active)
        }
        snapshot.appendItems(viewModel.sentDocuments.value, toSection: Section.sent)
        
        if viewModel.activeDocuments.value.isEmpty {
            snapshot.deleteSections([Section.active])
            isActiveSectionPresenting = false
        }
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private lazy var addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newDocument))
    
    private lazy var reloadButton = UIBarButtonItem(image: #imageLiteral(resourceName: "refresh"), style: .plain, target: self, action: #selector(reloadDocumentTypes))
    
    private lazy var hambugerButton: UIBarButtonItem = {
        let hambugerButton = HambugerButton()
        let tap = UITapGestureRecognizer(target: self, action: #selector(openMenu))
        hambugerButton.addGestureRecognizer(tap)
        hambugerButton.isUserInteractionEnabled = true
        hambugerButton.setup(username: viewModel.login.username)
        return UIBarButtonItem(customView: hambugerButton)
    }()
    
    private lazy var loadingItem: UIBarButtonItem = {
        let loading = UIActivityIndicatorView(style: .medium)
        loading.startAnimating()
        let button = UIBarButtonItem(customView: loading)
        button.isEnabled = false
        return button
    }()
    
    private lazy var headerView = HeaderView(frame: .zero)
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.registerCell(DocumentTableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.sectionFooterHeight = 50
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

extension DocumentsListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }
    
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let label = UILabel()
//        if tableView.numberOfSections == 1 {
//            label.text = "Sent"
//        } else {
//            label.text = section == 0 ? "Active" : "Sent"
//        }
//        return label
//     }
}

//MARK: - DocumentViewDelegate implementation
extension DocumentsListViewController: DocumentViewDelegate {
    func sent(_ document: DocumentViewModel) {
        viewModel.setDocumentAsSent(document)
        updateTableDataSource()
    }
}

private extension DocumentsListViewController {
    func makeDataSource() -> UITableViewDiffableDataSource<Section, DocumentViewModel> {
        return UITableViewDiffableDataSource<Section, DocumentViewModel>(
            tableView: self.tableView,
            cellProvider: {  (tableView, indexPath, document) in
                let cell = tableView.dequeueCell(DocumentTableViewCell.self)
                cell.setup(with: document, delegate: self)
                return cell
            }
        )
    }
}
