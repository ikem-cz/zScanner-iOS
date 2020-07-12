//
//  BodyPartDefectCoordinator.swift
//  zScanner
//
//  Created by Jakub Skořepa on 05/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol BodyPartDefectFlowDelegate: FlowDelegate {
    func defectSelected()
}

class BodyPartDefectCoordinator: Coordinator {

    // MARK: Instance part
    unowned private let flowDelegate: BodyPartDefectFlowDelegate
    private let folder: FolderDomainModel
    private var media: Media
    
    init(media: Media, folder: FolderDomainModel, flowDelegate: BodyPartDefectFlowDelegate, window: UIWindow, navigationController: UINavigationController? = nil) {
        self.flowDelegate = flowDelegate
        self.media = media
        self.folder = folder
        
        super.init(flowDelegate: flowDelegate, window: window, navigationController: navigationController)
    }
    
    // MARK: Interface
    func begin() {
        showBodyPartSelectionScreen()
    }
    
    private func showBodyPartSelectionScreen() {
        let viewModel = BodyPartViewModel(database: database, networkManager: networkManager, folder: folder, selectedBodyPart: media.defect?.bodyPartId)
        let viewController = BodyPartViewController(viewModel: viewModel, coordinator: self)
        push(viewController)
    }
    
    private func showBodyDefectSelectionScreen(for bodyPartId: String, list: ListPickerField<BodyDefectDomainModel>) {
        let viewController = BodyDefectCreationViewController(bodyPartId: bodyPartId, viewModel: list, coordinator: self)
        push(viewController)
    }
    
    // MARK: Helepers
    private let database: Database = try! RealmDatabase()
    private let networkManager: NetworkManager = IkemNetworkManager(api: NativeAPI())
}

extension BodyPartDefectCoordinator: ListItemSelectionCoordinator {
    func selected() {
        pop()
    }
}

extension BodyPartDefectCoordinator: BodyPartCoordinator {
    func showDefectSelector(for bodyPartId: String, list: ListPickerField<BodyDefectDomainModel>) {
        showBodyDefectSelectionScreen(for: bodyPartId, list: list)
    }
    
    func selected(_ defect: BodyDefectDomainModel) {
        media.defect = defect
        popAll()
        flowDelegate.coordinatorDidFinish(self)
    }
}
