//
//  NewDocumentFolderViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 10/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift


struct FolderSelection {
    let folder: FolderDomainModel
    let searchMode: SearchMode
}

protocol NewDocumentFolderCoordinator: BaseCoordinator {
    func folderSelected(_ folderSelection: FolderSelection)
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
        if parent == nil {
            self.setFocusToSearchBar()
        }
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
    
    private func showSearchResult(_ show: Bool) {
        if show {
            // Insert section if missing
            if sections.contains(.searchResults) == false {
                let index = 0
                sections.insert(.searchResults, at: index)
                tableView.insertSections([index], with: .fade)
            }
        } else {
            // Remove section if present
            if let index = sections.firstIndex(of: .searchResults) {
                sections.remove(at: index)
                tableView.deleteSections([index], with: .fade)
            }
        }
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
        
        if parent == nil {
            navigationItem.title = "newDocumentFolder.screen.title".localized
        } else {
            view.addSubview(presentedNavigationBar)
            presentedNavigationBar.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(21)
                make.leading.trailing.equalToSuperview()
            }
            
            presentedNavigationBar.addSubview(presentedTitle)
            presentedTitle.snp.makeConstraints { make in
                make.top.leading.bottom.equalToSuperview().inset(8)
            }
            
            presentedNavigationBar.addSubview(presentedScanButton)
            presentedScanButton.snp.makeConstraints { make in
                make.top.trailing.bottom.equalToSuperview().inset(8)
                make.leading.greaterThanOrEqualTo(presentedTitle.snp.trailing).offset(16)
            }
        }
        
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            if parent == nil {
                make.top.equalTo(safeArea)
            } else {
                make.top.equalTo(presentedNavigationBar.snp.bottom)
            }
            make.right.left.equalTo(safeArea)
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
        search.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
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
    
    private lazy var presentedNavigationBar = UIView()
    
    private lazy var presentedTitle: UILabel = {
        let label = UILabel()
        label.text = "newDocumentFolder.screen.title".localized
        label.textColor = .black
        label.numberOfLines = 1
        label.font = .headline
        label.textAlignment = .left
        return label
    }()
    
    private lazy var presentedScanButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "qrcode.viewfinder", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28)), for: .normal)
        button.setTitle("newDocumentFolder.scanButton.title".localized, for: .normal)
        button.setTitleColor(button.tintColor, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 4)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(scanBarcode), for: .touchUpInside)
        return button
    }()
}

// MARK: - Presentable implementation
extension NewDocumentFolderViewController: Presentable {
    func willDismiss() {
        searchBar.resignFirstResponder()
    }
    
    func willExpand() {
        // Nothing to do here
    }
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
        let searchMode: SearchMode
        
        switch section {
        case .searchResults:
            item = viewModel.searchResults.value[indexPath.row]
            searchMode = viewModel.lastUsedSearchMode
        case .history:
            item = viewModel.history[indexPath.row]
            searchMode = .history
        }
        
        guard item != .notFound else { return }
        
        coordinator.folderSelected(FolderSelection(folder: item, searchMode: searchMode))
    }
}

// MARK: - UISearchBarDelegate implementation
extension NewDocumentFolderViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        (parent as? BottomSheetPresenting)?.expandBottomSheet()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        var searchText = searchText
        
        if searchText.length >= Config.minimumSearchLength {
            viewModel.search(query: searchText)
        } else {
            searchText = ""
        }
        
        showSearchResult(!searchText.isEmpty)
    }
}

// MARK: - ScannerDelegate implementation
extension NewDocumentFolderViewController: ScannerDelegate {
    func close() {
        dismiss(animated: true, completion: nil)
        if viewModel.lastUsedSearchMode == .scan {
            showSearchResult(true)
        }
    }
    
    func failed() {
        dismiss(animated: true) { [weak self] in
            let alert = UIAlertController(title: "newDocumentFolder.scanFailedAlert.title".localized, message: "newDocumentFolder.scanFailedAlert.message".localized, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "alert.okButton.title".localized, style: .default))
            self?.present(alert, animated: true)
        }
    }
}
