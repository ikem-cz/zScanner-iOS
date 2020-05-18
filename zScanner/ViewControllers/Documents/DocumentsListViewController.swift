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
        
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.updateDocuments()
        tableView.reloadSections([0], with: .fade)
    }
    
    override var leftBarButtonItems: [UIBarButtonItem] {
        return [
            UIBarButtonItem(image: #imageLiteral(resourceName: "menuIcon"),style: .plain, target: self, action: #selector(openMenu))
        ]
    }
    
    override var rightBarButtonItems: [UIBarButtonItem] {
        return rightBarButtons
    }
    
    // MARK: Interface
    func insertNewDocument(document: DocumentViewModel) {
        viewModel.insertNewDocument(document)
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
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
    
    private func setupView() {
        navigationItem.title = "document.screen.title".localized
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.bottom.equalTo(safeArea)
            make.trailing.leading.equalToSuperview().inset(20)
        }
        
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
    
    private lazy var addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newDocument))
    
    private lazy var reloadButton = UIBarButtonItem(image: #imageLiteral(resourceName: "refresh"), style: .plain, target: self, action: #selector(reloadDocumentTypes))
    
    private lazy var loadingItem: UIBarButtonItem = {
        let loading = UIActivityIndicatorView(style: .gray)
        loading.startAnimating()
        let button = UIBarButtonItem(customView: loading)
        button.isEnabled = false
        return button
    }()
    
    private lazy var headerView = HeaderView(frame: .zero)
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.registerCell(DocumentTableViewCell.self)
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.tableFooterView = UIView()
        return tableView
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

//MARK: - UITableViewDataSource implementation
extension DocumentsListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = viewModel.documents.count
        tableView.backgroundView?.isHidden = count > 0
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let document = viewModel.documents[indexPath.row]
        let cell = tableView.dequeueCell(DocumentTableViewCell.self)
        cell.setup(with: document, delegate: self)
        return cell
    }
}

//MARK: - DocumentViewDelegate implementation
extension DocumentsListViewController: DocumentViewDelegate {}

extension UITableView {
    func updateHeaderViewHeight() {
        if let header = self.tableHeaderView {
            let newSize = header.systemLayoutSizeFitting(CGSize(width: self.bounds.width, height: 0))
            header.frame.size.height = newSize.height
        }
    }
}
