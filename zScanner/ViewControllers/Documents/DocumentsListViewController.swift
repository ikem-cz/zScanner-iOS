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

class DocumentsListViewController: BaseViewController {
    
    // MARK: - Instance part
    private unowned let coordinator: DocumentsListCoordinator
    private let viewModel: DocumentsListViewModel
    
    init(viewModel: DocumentsListViewModel, coordinator: DocumentsListCoordinator) {
        self.coordinator = coordinator
        self.viewModel = viewModel
        
        super.init(coordinator: coordinator)
    }
    
    override func loadView() {
        super.loadView()
        
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.reloadRocuments()
        tableView.reloadData()
    }
    
    override var rightBarButtonItems: [UIBarButtonItem] {
        return [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newDocument))
        ]
    }
    
    // MARK: Helpers
    @objc private func newDocument() {
        showDocumentModePicker()
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
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.registerCell(DocumentTableViewCell.self)
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.tableFooterView = UIView()
        return tableView
    }()
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
