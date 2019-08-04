//
//  NewDocumentTypeViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 01/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol NewDocumentTypeCoordinator: BaseCoordinator {}

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
    
    // MARK: Helpers
    private func setupView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        return tableView
    }()
}

// MARK: - UITableViewDataSource implementation
extension NewDocumentTypeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.fields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let item = viewModel.fields[indexPath.row]
        cell.textLabel?.text = item.title
        return cell
    }
}
