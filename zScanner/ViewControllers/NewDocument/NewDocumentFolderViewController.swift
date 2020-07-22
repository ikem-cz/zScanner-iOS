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
    class NewFolderDataSource: UITableViewDiffableDataSource<Section, FolderDomainModel> {

        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            let section = self.snapshot().sectionIdentifiers[section]
            return section.title
        }
    }
    
    enum Section: String {
        case searchResults
        case suggestedResult
        
        var title: String {
            switch self {
                case .searchResults: return "newDocumentFolder.searchResults.title".localized
                case .suggestedResult: return "newDocumentFolder.suggestedResults.title".localized
            }
        }
    }
    
    private let disposeBag = DisposeBag()
    
    private func clearSearchResults() {
        searchBar.text = ""
        viewModel.search(query: "")
    }
    
    private func setFocusToSearchBar() {
        searchBar.becomeFirstResponder()
    }
    
    @objc private func scanBarcode() {
        presentScanner()
    }
    
    private func setupBindings() {
        Observable
            .combineLatest(viewModel.suggestedResults, viewModel.searchResults)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] sugested, other in
                self?.updateTableView(suggested: sugested, other: other)
                
                if self?.viewModel.lastUsedSearchMode == .scan, let folder = other.first {
                    self?.coordinator.folderSelected(FolderSelection(folder: folder, searchMode: .scan))
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.isLoading
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] loading in
                self?.searchBar.isLoading = loading
            }).disposed(by: disposeBag)
    }
    
    private func updateTableView(suggested: [FolderDomainModel], other: [FolderDomainModel]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, FolderDomainModel>()
        
        tableView.backgroundView?.isHidden = !suggested.isEmpty || !other.isEmpty
        
        if !suggested.isEmpty {
            snapshot.appendSections([.suggestedResult])
            snapshot.appendItems(suggested, toSection: .suggestedResult)
        }
        
        if !other.isEmpty {
            snapshot.appendSections([.searchResults])
            snapshot.appendItems(other, toSection: .searchResults)
        }

        dataSource.apply(snapshot, animatingDifferences: true)
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
                make.leading.greaterThanOrEqualTo(presentedTitle.snp.trailing).offset(16).priority(999)
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
        
        tableView.dataSource = dataSource
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
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .white
        tableView.registerCell(FolderTableViewCell.self)
        
        let estimatedKeyboardHeight: CGFloat = 250
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: estimatedKeyboardHeight, right: 0)
        return tableView
    }()
    
    private lazy var dataSource: NewFolderDataSource = {
        let dataSource = NewFolderDataSource(
            tableView: self.tableView,
            cellProvider: { (tableView, indexPath, folder) in
                let cell = tableView.dequeueCell(FolderTableViewCell.self)
                cell.setup(with: folder)
                return cell
            }
        )
        dataSource.defaultRowAnimation = .fade
        return dataSource
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
    func willDismiss(afterCompleted: Bool) {
        searchBar.resignFirstResponder()
        if afterCompleted {
            clearSearchResults()
        }
    }
    
    func willExpand() {
        // Nothing to do here
    }
}

// MARK: - UITableViewDelegate implementation
extension NewDocumentFolderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath), item != .notFound else { return }
        
        coordinator.folderSelected(FolderSelection(folder: item, searchMode: viewModel.lastUsedSearchMode))
        searchBar.endEditing(true)
    }
}

// MARK: - UISearchBarDelegate implementation
extension NewDocumentFolderViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        (parent as? BottomSheetPresenting)?.expandBottomSheet()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let searchText = searchText.length < Config.minimumSearchLength ? "" : searchText
        viewModel.search(query: searchText)
        
        if searchText.isEmpty {
            updateTableView(suggested: [], other: [])
        }
    }
}

// MARK: - ScannerDelegate implementation
extension NewDocumentFolderViewController: ScannerDelegate {
    func close() {
        dismiss(animated: false, completion: nil)
        if viewModel.lastUsedSearchMode == .scan {
            (parent as? BottomSheetPresenting)?.expandBottomSheet()
            updateTableView(suggested: [], other: [])
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
