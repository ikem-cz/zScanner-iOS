//
//  BodyPartDefectCoordinator.swift
//  zScanner
//
//  Created by Jakub Skořepa on 05/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol BodyPartDefectFlowDelegate: FlowDelegate {}

class BodyPartDefectCoordinator: Coordinator {

    // MARK: Instance part
    unowned private let flowDelegate: BodyPartDefectFlowDelegate
    private let folder: FolderDomainModel
    private var media: Media
    private var newDefects: [BodyDefectDomainModel]
    
    init(media: Media, folder: FolderDomainModel, newDefects: [BodyDefectDomainModel], flowDelegate: BodyPartDefectFlowDelegate, window: UIWindow, navigationController: UINavigationController? = nil) {
        self.flowDelegate = flowDelegate
        self.media = media
        self.folder = folder
        self.newDefects = newDefects
        
        super.init(flowDelegate: flowDelegate, window: window, navigationController: navigationController)
        
        media.defect.flatMap({ self.newDefects.append($0) })
    }
    
    // MARK: Interface
    func begin() {
        showBodyPartSelectionScreen()
    }
    
    private func showBodyPartSelectionScreen() {
        let viewModel = BodyPartViewModel(database: database, networkManager: networkManager, folder: folder, selectedBodyPart: media.defect?.bodyPartId, newDefetcs: newDefects)
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
    private var defectSelection: ListPickerField<BodyDefectDomainModel>?
}

extension BodyPartDefectCoordinator: ListItemSelectionCoordinator {
    func selected() {
        guard let defect = defectSelection?.selected.value else { return }
        media.defect = defect
        popAll()
        flowDelegate.coordinatorDidFinish(self)
    }
}

extension BodyPartDefectCoordinator: BodyPartCoordinator {
    func showDefectSelector(for bodyPart: BodyPartDomainModel, defects: [BodyDefectDomainModel]) {
        
        let bodypartDefects = defects.filter({ $0.bodyPartId == bodyPart.id })
        let selectorTitle = "\("newDocument.defectList.title".localized) \(bodyPart.name)"
        self.defectSelection = ListPickerField(title: selectorTitle, list: bodypartDefects)
        
        showBodyDefectSelectionScreen(for: bodyPart.id, list: defectSelection!)
    }
}
