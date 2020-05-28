//
//  NewDocumentCoordinator.swift
//  zScanner
//
//  Created by Jakub Skořepa on 28/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol NewDocumentFlowDelegate: FlowDelegate {
    func newDocumentCreated(_ documentViewModel: DocumentViewModel)
}

class NewDocumentCoordinator: Coordinator {

    // MARK: Instance part
    unowned private let flowDelegate: NewDocumentFlowDelegate
    private var newDocument = DocumentDomainModel.emptyDocument
    private var folder: FolderDomainModel
    private var mediaViewModel: NewDocumentMediaViewModel?
    private let defaultMediaType = MediaType.photo
    private let mediaSourceTypes = [
         MediaType.photo,
         MediaType.video
     ]
    
    init?(folderSelection: FolderSelection, flowDelegate: NewDocumentFlowDelegate, window: UIWindow, navigationController: UINavigationController? = nil) {
        self.flowDelegate = flowDelegate
        self.folder = folderSelection.folder
        newDocument.folderId = folderSelection.folder.id
        
        super.init(window: window, navigationController: navigationController)
        
        FolderDatabaseModel.updateLastUsage(of: folderSelection.folder)
        tracker.track(.userFoundBy(folderSelection.searchMode))
    }
    
    // MARK: Interface
    func begin() {
        showNewMediaScreen(mediaType: defaultMediaType, mediaSourceTypes: mediaSourceTypes)
    }
    
    // MARK: Helepers
    private let database: Database = try! RealmDatabase()
    private let networkManager: NetworkManager = IkemNetworkManager(api: NativeAPI())
    private let tracker: Tracker = FirebaseAnalytics()
    
    // TODO: Remove this function later
    private func showDocumentTypeSelectionScreen() {
        let viewModel = NewDocumentTypeViewModel(documentMode: .document, database: database)
        let viewController = NewDocumentTypeViewController(viewModel: viewModel, coordinator: self)
        push(viewController)
    }
    
    private func showNewMediaScreen(mediaType: MediaType, mediaSourceTypes: [MediaType]) {
        if !(viewControllers.first is CameraViewController) {
            popAll(animated: false)
        }
        
        let viewModel = CameraViewModel(initialMode: mediaType, folderName: folder.name, correlationId: newDocument.id, mediaSourceTypes: mediaSourceTypes)
        let viewController = CameraViewController(viewModel: viewModel, coordinator: self)
        
        if let index = navigationController?.viewControllers.firstIndex(where: { $0 is CameraViewController }) {
            navigationController?.viewControllers.insert(viewController, at: index)
            if let localIndex = viewControllers.firstIndex(where: { $0 is CameraViewController }) {
                viewControllers.insert(viewController, at: localIndex)
            }
            pop(to: viewController, animated: true)
        } else {
            push(viewController, animated: true)
        }
    }
    
    private func showPhotoPreviewScreen(media: Media) {
        guard let mediaViewModel = mediaViewModel else { return }
        let viewController = PhotoPreviewViewController(media: media, viewModel: mediaViewModel, coordinator: self)
        push(viewController)
    }
    
    private func showVideoPreviewScreen(media: Media) {
        guard let mediaViewModel = mediaViewModel else { return }
        let viewController = VideoPreviewViewController(media: media, viewModel: mediaViewModel, coordinator: self)
        push(viewController)
    }
    
    private func showMediaListScreen() {
        guard let mediaViewModel = mediaViewModel else { return }
        let viewController = MediaListViewController(viewModel: mediaViewModel, coordinator: self)
        push(viewController)
    }
    
    private func showListItemSelectionScreen<T: ListItem>(for list: ListPickerField<T>) {
        let viewController = ListItemSelectionViewController(viewModel: list, coordinator: self)
        push(viewController)
    }
    
    private func finish() {
        let databaseDocument = DocumentDatabaseModel(document: newDocument)
        database.saveObject(databaseDocument)
        
        let documentViewModel = DocumentViewModel(document: newDocument, networkManager: networkManager, database: database)
        documentViewModel.uploadDocument()
        
        popAll()
        flowDelegate.newDocumentCreated(documentViewModel)
        flowDelegate.coordinatorDidFinish(self)
    }
    
    private func saveMediaToDocument(_ media: [Media]) {
        // Store media
        media
            .enumerated()
            .forEach({ (index, media) in
                let media = MediaDomainModel(media: media, index: index)
                newDocument.pages.append(media)
            })
    }
    
    // MARK: - BaseCordinator implementation
    override func willPreventPop(for sender: BaseViewController) -> Bool {
        switch sender {
        case
        is MediaListViewController,
        is NewDocumentTypeViewController,
        is NewDocumentFolderViewController:
            return true
        default:
            return false
        }
    }
    
    override func backButtonPressed(sender: BaseViewController) {
        if willPreventPop(for: sender) {
            showPopConfirmationDialog(presentOn: sender, popHandler: { [unowned self] in
                self.pop()
            })
        } else {
            super.backButtonPressed(sender: sender)
        }
    }

    private func showPopConfirmationDialog(presentOn viewController: BaseViewController, popHandler: @escaping EmptyClosure) {
        let alert = UIAlertController(title: "newDocument.popAlert.title".localized, message: "newDocument.popAlert.message".localized, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "newDocument.popAlert.confirm".localized, style: .default, handler: { _ in popHandler() }))
        alert.addAction(UIAlertAction(title: "newDocument.popAlert.cancel".localized, style: .cancel, handler: nil))
        
        viewController.present(alert, animated: true)
    }
}

// MARK: - CameraCoordinator implementation
extension NewDocumentCoordinator: CameraCoordinator {
    func mediaCreated(_ media: Media) {
        if mediaViewModel == nil {
            mediaViewModel = NewDocumentMediaViewModel(folderName: folder.name, mediaType: media.type, tracker: tracker)
        }
        
        if media.type == .photo {
            showPhotoPreviewScreen(media: media)
        } else if media.type == .video {
            showVideoPreviewScreen(media: media)
        }
    }
}

// MARK: - MediaPreviewCoordinator implementation
extension NewDocumentCoordinator: MediaPreviewCoordinator {
    func createNewMedia(mediaType: MediaType) {
        guard let mediaViewModel = mediaViewModel else { return }
        showNewMediaScreen(mediaType: mediaViewModel.mediaType, mediaSourceTypes: [mediaViewModel.mediaType])
    }
    
    func finishEdit() {
        if let mediaListViewController = navigationController?.viewControllers.first(where: { $0 is MediaListViewController }) as? BaseViewController {
            pop(to: mediaListViewController)
        } else {
            showMediaListScreen()
        }
    }
}

// MARK: - NewDocumentMediaCoordinator implementation
extension NewDocumentCoordinator: MediaListCoordinator {
    func upload() {
        saveMediaToDocument((mediaViewModel?.mediaArray.value)!)
        finish()
    }
    
    func reeditMedium(media: Media) {
        if media.type == .photo {
            showPhotoPreviewScreen(media: media)
        } else if media.type == .video {
            showVideoPreviewScreen(media: media)
        }
    }
}

// MARK: - NewDocumentTypeCoordinator implementation
extension NewDocumentCoordinator: NewDocumentTypeCoordinator {
    func showSelector<T: ListItem>(for list: ListPickerField<T>) {
        showListItemSelectionScreen(for: list)
    }
    
    func saveFields(_ fields: [FormField]) {
        for field in fields {
            switch field {
            case let textField as TextInputField:
                newDocument.notes = textField.text.value
            case let datePicker as DateTimePickerField:
                if let date = datePicker.date.value {
                    newDocument.date = date
                }
            case let listPicker as ListPickerField<DocumentTypeDomainModel>:
                if let type = listPicker.selected.value {
                    newDocument.type = type
                }
            default:
                break
            }
        }
    }
}

// MARK: - ListItemSelectionCoordinator implementation
extension NewDocumentCoordinator: ListItemSelectionCoordinator {}
