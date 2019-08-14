//
//  DocumentsCoordinator.swift
//  zScanner
//
//  Created by Jakub Skořepa on 26/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RealmSwift
import RxSwift

protocol DocumentsFlowDelegate: FlowDelegate {
    func logout()
}

// MARK: -
class DocumentsCoordinator: Coordinator {
    
    // MARK: Instance part
    unowned private let flowDelegate: DocumentsFlowDelegate
    
    init(flowDelegate: DocumentsFlowDelegate, window: UIWindow) {
        self.flowDelegate = flowDelegate
        self.networkManager = IkemNetworkManager(api: api)
        
        super.init(window: window)
    }
    
    // MARK: Interface
    private lazy var viewModel: DocumentsListViewModel = {
        return DocumentsListViewModel(database: database, ikemNetworkManager: networkManager)
    }()
    func begin() {
        showDocumentsListScreen(viewModel)
        setupMenu(viewModel)
    }
    
    // MARK: Navigation methods
    private func showDocumentsListScreen(_ viewModel: DocumentsListViewModel) {
        let viewController = DocumentsListViewController(viewModel: viewModel, coordinator: self)
        push(viewController)

    }
    private lazy var menuCoordinator: MenuCoordinator = {
        return MenuCoordinator(flowDelegate: self, window: window, navigationController: navigationController)
    }()
    private func setupMenu(_ viewModel: DocumentsListViewModel) {
        addChildCoordinator(menuCoordinator)
        menuCoordinator.begin()
    }
    
    private func runNewDocumentFlow(with mode: DocumentMode) {
        guard let coordinator = NewDocumentCoordinator(for: mode, flowDelegate: self, window: window, navigationController: navigationController) else { return }
        addChildCoordinator(coordinator)
        coordinator.begin()
    }
    
    // MARK: Helpers
    private let api: API = NativeAPI()
    private let networkManager: NetworkManager
    private let database: Database = try! Realm()
    private let tracker: Tracker = FirebaseAnalytics()
}

// MARK: - DocumentsListCoordinator implementation
extension DocumentsCoordinator: DocumentsListCoordinator {
    func createNewDocument(with mode: DocumentMode) {
        tracker.track(.documentModeSelected(mode))
        runNewDocumentFlow(with: mode)
    }
    func openDrawer() {
        menuCoordinator.openDrawer()
    }
}

// MARK: - NewDocumentFlowDelegate implementation
extension DocumentsCoordinator: NewDocumentFlowDelegate {
    func newDocumentCreated(_ documentViewModel: DocumentViewModel) {
        guard let list = viewControllers.last as? DocumentsListViewController else {
            assertionFailure()
            return
        }
        
        list.insertNewDocument(document: documentViewModel)
    }
}

// MARK: - MenuFlowDelegate implementation
extension DocumentsCoordinator: MenuFlowDelegate {
    func logout() {
        flowDelegate.logout()
    }
    func deleteHistory() {
        viewModel.deleteHistory()
    }
}
