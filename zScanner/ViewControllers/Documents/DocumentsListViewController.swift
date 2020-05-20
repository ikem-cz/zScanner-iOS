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
        
        setupBindings()
        update()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.updateDocuments()
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
        // Remove bottom line of navbar
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.bottom.equalTo(safeArea)
            make.trailing.leading.equalToSuperview().inset(20)
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
    
    func update() {
        var snapshot = dataSource.snapshot()
        
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(viewModel.activeDocuments, toSection: Section.active)
        snapshot.appendItems(viewModel.sentDocuments, toSection: Section.sent)
        
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
        let tableView = UITableView()
        tableView.registerCell(DocumentTableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.tableFooterView = UIView()
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

//MARK: - UITableViewDataSource implementation
//extension DocumentsListViewController: UITableViewDataSource {
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return Section.allCases.count
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        var count = 0
//        if section == Section.active.hashValue {
//            count = viewModel.activeDocuments.count
//            tableView.backgroundView?.isHidden = count > 0
//        } else {
//            count = viewModel.sentDocuments.count
//            tableView.backgroundView?.isHidden = count > 0
//        }
//        return count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let document = viewModel.activeDocuments[indexPath.row]
//        let cell = tableView.dequeueCell(DocumentTableViewCell.self)
//        cell.setup(with: document, delegate: self)
//        cell.selectionStyle = UITableViewCell.SelectionStyle.none
//
//        // Set rounded top and bottom corners
//        if tableView.numberOfRows(inSection: indexPath.section) == 1 {
//            cell.roundedCorners(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner], radius: 16)
//            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
//            return cell
//        }
//
//        // Set rounded top corners
//        if indexPath.row == 0 {
//            cell.roundedCorners(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], radius: 16)
//            return cell
//        }
//
//        // Set rounded bottom corners
//        if indexPath.row == (viewModel.activeDocuments.count-1) {
//            cell.roundedCorners(corners: [.layerMaxXMaxYCorner, .layerMinXMaxYCorner], radius: 16)
//            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
//            return cell
//        }
//
//        return cell
//    }
//}

//MARK: - DocumentViewDelegate implementation
extension DocumentsListViewController: DocumentViewDelegate {
    func sent(document: DocumentViewModel) {
        print("sent")
        viewModel.setDocumentAsSent(document)
        update()
    }
}

private extension DocumentsListViewController {
    func makeDataSource() -> UITableViewDiffableDataSource<Section, DocumentViewModel> {
        return UITableViewDiffableDataSource<Section, DocumentViewModel>(
            tableView: self.tableView,
            cellProvider: {  (tableView, indexPath, _) in
                let cell = tableView.dequeueCell(DocumentTableViewCell.self)

                if indexPath.section == Section.active.hashValue {
                    let activeDocument = self.viewModel.activeDocuments[indexPath.row]
                    cell.setup(with: activeDocument, delegate: self)
                } else {
                    let sentDocument = self.viewModel.activeDocuments[indexPath.row]
                    cell.setup(with: sentDocument, delegate: self)
                }
                cell.selectionStyle = UITableViewCell.SelectionStyle.none

                // Set rounded top and bottom corners
                if tableView.numberOfRows(inSection: indexPath.section) == 1 {
                    cell.roundedCorners(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner], radius: 16)
                    cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                    return cell
                }

                // Set rounded top corners
                if indexPath.row == 0 {
                    cell.roundedCorners(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], radius: 16)
                    return cell
                }

                // Set rounded bottom corners
                if indexPath.row == (self.viewModel.activeDocuments.count-1) {
                    cell.roundedCorners(corners: [.layerMaxXMaxYCorner, .layerMinXMaxYCorner], radius: 16)
                    cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
                    return cell
                }
                
                return cell
            }
        )
    }
}
