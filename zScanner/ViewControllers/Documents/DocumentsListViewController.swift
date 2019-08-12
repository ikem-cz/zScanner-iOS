//
//  DocumentsListViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 21/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RealmSwift
import RxSwift

protocol DocumentsListCoordinator: BaseCoordinator {
    func createNewDocument(with mode: DocumentMode)
}

protocol DrawerDelegate {
    func showDrawer()
}

class DocumentsListViewController: BaseViewController {
    
    // MARK: - Instance part
    private unowned let coordinator: DocumentsListCoordinator
    private let viewModel: DocumentsListViewModel
    
    var drawerDelegate: DrawerDelegate!
    
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
    
    override var leftBarButtonItems: [UIBarButtonItem] {
        return [
            UIBarButtonItem(image: UIImage(named:"menuIcon"),style: .plain, target: self, action: #selector(hamburgerTap))
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
                case .error:
                    self.rightBarButtons = []
                    // TODO: Show error dialog
                }
            })
            .disposed(by: disposeBag)
    }
    
    @objc private func newDocument() {
        showDocumentModePicker()
    }
    @objc private func hamburgerTap() {
        showDrawer()
    }
    
    private func showDocumentModePicker() {
        let modes = viewModel.documentModes
        
        let handler: (DocumentMode) -> Void = { [weak self] mode in
            self?.coordinator.createNewDocument(with: mode)
        }
        
        var actions = modes.map({ mode in
            UIAlertAction(
                title: mode.title,
                style: .default,
                handler: { _ in handler(mode) }
            )
        })
        actions.append(
            UIAlertAction(title: "document.modeSelector.cancel".localized, style: .cancel, handler: { _ in })
        )
        
        let alert = UIAlertController(title: "document.modeSelector.title".localized, message: nil, preferredStyle: .actionSheet)
        actions.forEach({ alert.addAction($0) })
        present(alert, animated: true, completion: nil)
    }
    
    private func setupView() {
        navigationItem.title = "document.screen.title".localized
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private lazy var addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newDocument))
    
    private lazy var loadingItem: UIBarButtonItem = {
        let loading = UIActivityIndicatorView(style: .gray)
        loading.startAnimating()
        let button = UIBarButtonItem(customView: loading)
        button.isEnabled = false
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.registerCell(DocumentTableViewCell.self)
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.tableFooterView = UIView()
        return tableView
    }()
    private func showDrawer() {
        drawerDelegate.showDrawer()
    }
}

//MARK: - UITableViewDataSource implementation
extension DocumentsListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.documents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let document = viewModel.documents[indexPath.row]
        let cell = tableView.dequeueCell(DocumentTableViewCell.self)
        cell.setup(with: document)
        return cell
    }
}
