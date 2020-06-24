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
    private var mediaViewModel: MediaListViewModel?
    private let defaultMediaType = MediaType.photo
    #warning("Should depend on document modes?")
    private let mediaSourceTypes = [
        MediaType.photo,
        MediaType.video,
        MediaType.scan
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
    
    private func showNewMediaScreen(mediaType: MediaType, mediaSourceTypes: [MediaType]) {
        if !(viewControllers.first is CameraViewController) {
            popAll(animated: false)
        }
        
        let viewModel = CameraViewModel(initialMode: mediaType, folderName: folder.name, correlationId: newDocument.id, mediaSourceTypes: mediaSourceTypes)
        let viewController = CameraViewController(viewModel: viewModel, coordinator: self)
        push(viewController, animated: true)
    }
    
    private func showPreviewScreen(for media: Media, editing: Bool = false) {
        let viewController = mediaScreen(for: media, editing: editing)
        push(viewController, animated: true)
    }
    
    private func mediaScreen(for media: Media, editing: Bool) -> MediaPreviewViewController {
        if mediaViewModel == nil || mediaViewModel?.mediaArray.value.isEmpty == true {
            mediaViewModel = MediaListViewModel(database: database, folderName: folder.name, mediaType: media.type, tracker: tracker)
        }
        let viewModel = mediaViewModel!

        switch media.type {
        case .photo:
            return PhotoPreviewViewController(media: media, viewModel: viewModel, coordinator: self, editing: editing)
        case .video:
            return VideoPreviewViewController(media: media, viewModel: viewModel, coordinator: self, editing: editing)
        case .scan:
            return ScanPreviewViewController(media: media as! ScanMedia, viewModel: viewModel, coordinator: self, editing: editing)
        }
    }
    
    private func showMediaListScreen() {
        if let mediaListViewController = navigationController?.viewControllers.first(where: { $0 is MediaListViewController }) as? BaseViewController {
            pop(to: mediaListViewController)
        } else {
            guard let mediaViewModel = mediaViewModel else { return }
            let viewController = MediaListViewController(viewModel: mediaViewModel, coordinator: self)
            push(viewController)
        }
    }
    
    private func showListItemSelectionScreen<T: ListItem>(for list: ListPickerField<T>) {
        let viewController = ListItemSelectionViewController(viewModel: list, coordinator: self)
        push(viewController)
    }
    
    private func finish() {
        switch mediaViewModel?.mediaType {
        case .photo:
            newDocument.type.mode = DocumentMode.photo
        case .video:
            newDocument.type.mode = DocumentMode.video
        case .scan:
            // Will get from SegmentControllField
            break
        default:
            print("Unknown mediaType.")
        }
        
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
    
    private func deleteMedia() {
        #warning("TODO")
        // TODO: Create a folder structure `/FolderId/DocumentId/MediaId.jpg` and remove the document properly
        let folderURL = URL(documentsWith: newDocument.id)
        do {
            try FileManager.default.removeItem(at: folderURL)
        } catch let error as NSError {
            print("Error: \(error.domain)")
        }
    }
    
    // MARK: - BaseCordinator implementation
    override func willPreventPop(for sender: BaseViewController) -> Bool {
        switch sender {
        case is MediaListViewController,
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
        showPreviewScreen(for: media)
    }
}

// MARK: - MediaPreviewCoordinator implementation
extension NewDocumentCoordinator: MediaPreviewCoordinator {
    func createNewMedia() {
        guard let mediaViewModel = mediaViewModel else { return }
        if mediaViewModel.mediaArray.value.isEmpty {
            showNewMediaScreen(mediaType: defaultMediaType, mediaSourceTypes: mediaSourceTypes)
        } else {
            showNewMediaScreen(mediaType: mediaViewModel.mediaType, mediaSourceTypes: [mediaViewModel.mediaType])
        }
    }
    
    func finishEdit() {
        showMediaListScreen()
    }
}

// MARK: - NewDocumentMediaCoordinator implementation
extension NewDocumentCoordinator: MediaListCoordinator {
    func showSelector<T: ListItem>(for list: ListPickerField<T>) {
        showListItemSelectionScreen(for: list)
    }
    
    func upload(_ fields: [[FormField]]) {
        for section in fields {
            for field in section {
                switch field {
                case let segmentControl as SegmentPickerField<DocumentMode>:
                    segmentControl.selected.value.flatMap({ newDocument.type.mode = $0 })
                case let textField as TextInputField:
                    newDocument.notes = textField.text.value
                case let datePicker as DateTimePickerField:
                    datePicker.date.value.flatMap({ newDocument.date = $0 })
                case let listPicker as ListPickerField<DocumentTypeDomainModel>:
                    listPicker.selected.value.flatMap({ newDocument.type = $0 })
                default:
                    break
                }
            }
        }
        
        saveMediaToDocument((mediaViewModel?.mediaArray.value)!)
        finish()
    }
    
    func reeditMedia(media: Media) {
        showPreviewScreen(for: media, editing: true)
    }
    
    func deleteDocument() {
        deleteMedia()
        popAll()
        flowDelegate.coordinatorDidFinish(self)
    }
}

// MARK: - ListItemSelectionCoordinator implementation
extension NewDocumentCoordinator: ListItemSelectionCoordinator {}
