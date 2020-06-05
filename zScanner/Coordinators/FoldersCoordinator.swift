//
//  FoldersCoordinator.swift
//  zScanner
//
//  Created by Jakub Skořepa on 26/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift

protocol FoldersFlowDelegate: FlowDelegate {
    func logout()
}

// MARK: -
class FoldersCoordinator: Coordinator {
    
    // MARK: Instance part
    unowned private let flowDelegate: FoldersFlowDelegate
    private let userSession: UserSession
    
    init(userSession: UserSession, flowDelegate: FoldersFlowDelegate, window: UIWindow) {
        self.userSession = userSession
        self.flowDelegate = flowDelegate
        self.networkManager = IkemNetworkManager(api: api)
        
        super.init(window: window)
        
        setupSessionHandler()
    }
    
    // MARK: Interface
    func begin() {
        showFoldersListScreen()
        setupMenu()
    }
    
    // MARK: Navigation methods
    private lazy var foldersListViewController: FoldersListViewController = {
        let viewModel = FoldersListViewModel(database: database, login: userSession.login, ikemNetworkManager: networkManager)
        let viewController = FoldersListViewController(viewModel: viewModel, coordinator: self)
        return viewController
    }()
    
    private func showFoldersListScreen() {
        foldersListViewController.sheetViewController = folderSearchScreen
        push(foldersListViewController)
    }
    
    private var folderSearchScreen: NewDocumentFolderViewController {
        let viewModel = NewDocumentFolderViewModel(database: database, networkManager: networkManager, tracker: tracker)
        let viewController = NewDocumentFolderViewController(viewModel: viewModel, coordinator: self)
        return viewController
    }
    
    private lazy var menuCoordinator: MenuCoordinator = {
        return MenuCoordinator(login: userSession.login, flowDelegate: self, window: window, navigationController: navigationController)
    }()
    
    private func setupMenu() {
        addChildCoordinator(menuCoordinator)
        menuCoordinator.begin()
    }
    
    private func runNewDocumentFlow(with folderSelection: FolderSelection) {
        // Tracking
        if documentCreatedInThisSession {
            tracker.track(.createDocumentAgain)
        } else {
            documentCreatedInThisSession = true
        }
        
        // Start new-document flow
        guard let coordinator = NewDocumentCoordinator(
            folderSelection: folderSelection,
            flowDelegate: self,
            window: window,
            navigationController: navigationController
        ) else { return }
        
        addChildCoordinator(coordinator)
        coordinator.begin()
    }
    
    // MARK: Helpers
    private let api: API = NativeAPI()
    private let networkManager: NetworkManager
    private let database: Database = try! RealmDatabase()
    private let tracker: Tracker = FirebaseAnalytics()
    private var documentCreatedInThisSession = false
    
    private func setupSessionHandler() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appEnteredBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    @objc private func appEnteredBackground() {
        documentCreatedInThisSession = true
    }
}

// MARK: - DocumentsListCoordinator implementation
extension FoldersCoordinator: FoldersListCoordinator {
    func createNewDocument(with folderSelection: FolderSelection) {
        runNewDocumentFlow(with: folderSelection)
    }
    
    func openMenu() {
        menuCoordinator.openMenu()
    }
}

// MARK: - NewDocumentFlowDelegate implementation
extension FoldersCoordinator: NewDocumentFlowDelegate {
    func newDocumentCreated(_ documentViewModel: DocumentViewModel) {
        guard let list = viewControllers.last as? FoldersListViewController else {
            assertionFailure()
            return
        }
        
        list.dismissBottomSheet(afterCompleted: true)
        list.insertNewDocument(document: documentViewModel)
    }
}

// MARK: - MenuFlowDelegate implementation
extension FoldersCoordinator: MenuFlowDelegate {
    func deleteHistory() {
        
        //Tracking
        let numberOfDocuments = database.loadObjects(DocumentDatabaseModel.self).count
        tracker.track(.numberOfDocumentsBeforeDelete(numberOfDocuments))
        
        // Deleting
        database.deleteAll(of: PageDatabaseModel.self)
        database.deleteAll(of: DocumentDatabaseModel.self)
        database.deleteAll(of: PageUploadStatusDatabaseModel.self)
        database.deleteAll(of: DocumentUploadStatusDatabaseModel.self)
        database.deleteAll(of: FolderDatabaseModel.self)
        
        foldersListViewController.updateViewModel()
    }
    
    func logout() {
        deleteHistory()
        flowDelegate.logout()
        flowDelegate.coordinatorDidFinish(self)
    }
}

// MARK: - NewDocumentTypeCoordinator implementation
extension FoldersCoordinator: NewDocumentFolderCoordinator {
    func folderSelected(_ folderSelection: FolderSelection) {
        runNewDocumentFlow(with: folderSelection)
    }
}
