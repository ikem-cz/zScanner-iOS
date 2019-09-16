//
//  NewDocumentFolderViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 10/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift

protocol NewDocumentFolderCoordinator: BaseCoordinator {
    func saveFolder(_ folder: FolderDomainModel)
    func showNextStep()
}

// MARK: -
class NewDocumentFolderViewController: BaseViewController {
    
    // MARK: Instance part
    private unowned let coordinator: NewDocumentFolderCoordinator
    private let viewModel: NewDocumentFolderViewModel
    
    init(viewModel: NewDocumentFolderViewModel, coordinator: NewDocumentFolderCoordinator) {
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
        self.setFocusToSearchBar()
    }

    override var rightBarButtonItems: [UIBarButtonItem] {
        return [
            UIBarButtonItem(image: #imageLiteral(resourceName: "barcode"), style: .plain, target: self, action: #selector(scanBarcode))
        ]
    }
    
    // MARK: Helpers
    enum Section: String {
        case searchResults
        case history
        
        var title: String {
            switch self {
                case .searchResults: return "newDocumentFolder.searchResults.title".localized
                case .history: return "newDocumentFolder.searchHistory.title".localized
            }
        }
    }
    
    private var sections: [Section] = []
    private let disposeBag = DisposeBag()
    
    private func setFocusToSearchBar() {
        searchBar.becomeFirstResponder()
    }
    
    @objc private func scanBarcode() {
        presentScanner()
    }
    
    private func setupBindings() {
        viewModel.searchResults
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let section = self?.sections.firstIndex(of: .searchResults) else { return }
                self?.tableView.reloadSections([section], with: .fade)
            }).disposed(by: disposeBag)
        
        viewModel.isLoading
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] loading in
                self?.searchBar.isLoading = loading
            }).disposed(by: disposeBag)
    }
    
    private func presentScanner() {
        let scanner = ScannerViewController(viewModel: viewModel, delegate: self)
        let navigationController = UINavigationController(rootViewController: scanner)
        present(navigationController, animated: true, completion: nil)
    }
    
    private func setupView() {
        navigationItem.title = "newDocumentFolder.screen.title".localized
        
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.right.left.equalTo(safeArea)
            make.height.equalTo(56) // Default searchBar height
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.right.bottom.left.equalToSuperview()
        }
        
        if !viewModel.history.isEmpty {
            sections.append(.history)
        }
        
        tableView.backgroundView = emptyView
        
        emptyView.addSubview(emptyViewLabel)
        emptyViewLabel.snp.makeConstraints { make in
            make.width.equalToSuperview().multipliedBy(0.75)
            make.centerX.equalToSuperview()
            make.top.greaterThanOrEqualTo(tableView.safeAreaLayoutGuide.snp.top)
            make.centerY.equalToSuperview().multipliedBy(0.36).priority(900)
        }
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .white
        tableView.registerCell(FolderTableViewCell.self)
        return tableView
    }()
    
    private lazy var searchBar: UISearchBar = {
        let search = UISearchBar()
        search.delegate = self
        search.placeholder = "newDocumentFolder.searchBar.title".localized
        search.sizeToFit()
        return search
    }()
    
    private lazy var emptyView = UIView()
    
    private lazy var emptyViewLabel: UILabel = {
        let label = UILabel()
        label.text = "newDocumentFolder.emptyView.title".localized
        label.textColor = .black
        label.numberOfLines = 0
        label.font = .body
        label.textAlignment = .center
        return label
    }()
}

// MARK: - UITableViewDataSource implementation
extension NewDocumentFolderViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        let count = sections.count
        tableView.backgroundView?.isHidden = count > 0
        return count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = sections[section]
        switch section {
        case .searchResults:
            return viewModel.searchResults.value.count
        case .history:
            return viewModel.history.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sections[indexPath.section]
        
        let folder: FolderDomainModel
        
        switch section {
        case .searchResults:
            folder = viewModel.searchResults.value[indexPath.row]
        case .history:
            folder = viewModel.history[indexPath.row]
        }
        
        let cell = tableView.dequeueCell(FolderTableViewCell.self)
        cell.setup(with: folder)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
}

// MARK: - UITableViewDelegate implementation
extension NewDocumentFolderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        
        let item: FolderDomainModel
        
        switch section {
        case .searchResults:
            item = viewModel.searchResults.value[indexPath.row]
        case .history:
            item = viewModel.history[indexPath.row]
        }
        
        coordinator.saveFolder(item)
        coordinator.showNextStep()
    }
}

// MARK: - UISearchBarDelegate implementation
extension NewDocumentFolderViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        var searchText = searchText
        
        if searchText.length >= Config.minimumSearchLength {
            viewModel.search(query: searchText)
        } else {
            searchText = ""
        }
        
        if searchText.isEmpty {
            // Remove section if present
            if let index = sections.firstIndex(of: .searchResults) {
                sections.remove(at: index)
                tableView.deleteSections([index], with: .fade)
            }
        } else {
            // Insert section if missing
            if sections.contains(.searchResults) == false {
                let index = 0
                sections.insert(.searchResults, at: index)
                tableView.insertSections([index], with: .fade)
            }
        }
    }
}

// MARK: - ScannerDelegate implementation
extension NewDocumentFolderViewController: ScannerDelegate {
    func close() {
        dismiss(animated: true, completion: nil)
    }
    
    func failed() {
        dismiss(animated: true) { [weak self] in
            let alert = UIAlertController(title: "newDocumentFolder.scanFailedAlert.title".localized, message: "newDocumentFolder.scanFailedAlert.message".localized, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "alert.okButton.title".localized, style: .default))
            self?.present(alert, animated: true)
        }
    }
}
