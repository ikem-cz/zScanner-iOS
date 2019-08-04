//
//  DocumentsCoordinator.swift
//  zScanner
//
//  Created by Jakub Skořepa on 26/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RealmSwift

protocol DocumentsFlowDelegate: FlowDelegate {}

// MARK: -
class DocumentsCoordinator: Coordinator {
    
    // MARK: Instance part
    unowned private let flowDelegate: DocumentsFlowDelegate
    
    init(flowDelegate: DocumentsFlowDelegate, window: UIWindow) {
        self.flowDelegate = flowDelegate
        self.ikemNetworkManager = IkemNetworkManager(api: api)
        
        super.init(window: window)
    }
    
    // MARK: Interface
    func begin() {
        fetchDocumentTypes { [weak self] in
            DispatchQueue.main.async {
                self?.showDocumentsListScreen()
            }
        }
    }
    
    // MARK: Navigation methods
    private func showDocumentsListScreen() {
        let viewModel = DocumentsListViewModel(database: database)
        let viewController = DocumentsListViewController(viewModel: viewModel, coordinator: self)
        push(viewController)
    }
    
    private func runNewDocumentFlow(with mode: DocumentMode) {
        guard let coordinator = NewDocumentCoordinator(for: mode, flowDelegate: self, window: window, navigationController: navigationController) else { return }
        addChildCoordinator(coordinator)
        coordinator.begin()
    }
    
    // MARK: Helpers
    private let api: API = NativeAPI()
    private let ikemNetworkManager: IkemNetworkManaging
    private let database: Database = try! Realm()
    private let tracker: Tracker = FirebaseAnalytics()
    
    private func fetchDocumentTypes(callback: @escaping EmptyClosure) {
        ikemNetworkManager.getDocumentTypes { [weak self] requestStatus in
            switch requestStatus {
            case .success(data: let networkModel):
                let types = networkModel.map({
                    DocumentTypeDomainModel(
                        id: $0.type,
                        name: $0.display,
                        mode: DocumentMode.init(rawValue: $0.mode) ?? .undefined
                    )
                })
                self?.storeDocumentTypes(types)
                callback()
            default:
                // TODO: maybe use some other cases?
                break
            }
        }
    }
    
    private func storeDocumentTypes(_ types: [DocumentTypeDomainModel]) {
        types
            .map({ DocumentTypeDatabaseModel(documentType: $0) })
            .forEach({ database.saveObject($0) })
    }
}

// MARK: - DocumentsListCoordinator implementation
extension DocumentsCoordinator: DocumentsListCoordinator {
    func createNewDocument(with mode: DocumentMode) {
        tracker.track(.documentModeSelected(mode))
        runNewDocumentFlow(with: mode)
    }
}

// MARK: - NewDocumentFlowDelegate implementation
extension DocumentsCoordinator: NewDocumentFlowDelegate {}
