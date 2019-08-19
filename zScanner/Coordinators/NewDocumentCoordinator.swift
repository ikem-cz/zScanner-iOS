//
//  NewDocumentCoordinator.swift
//  zScanner
//
//  Created by Jakub Skořepa on 28/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RealmSwift

protocol NewDocumentFlowDelegate: FlowDelegate {
    func newDocumentCreated(_ documentViewModel: DocumentViewModel)
}

class NewDocumentCoordinator: Coordinator {
    enum Step: Equatable {
        case folder
        case documentType
        case photos
    }
    
    // MARK: Instance part
    unowned private let flowDelegate: NewDocumentFlowDelegate
    private var newDocument = DocumentDomainModel.emptyDocument
    private let mode: DocumentMode
    private let steps: [Step]
    private var currentStep: Step
    
    init?(for mode: DocumentMode, flowDelegate: NewDocumentFlowDelegate, window: UIWindow, navigationController: UINavigationController? = nil) {
        guard mode != .undefined else { return nil }

        self.flowDelegate = flowDelegate
        
        self.mode = mode
        self.steps = NewDocumentCoordinator.steps(for: mode)
        
        // If mode is .photo the step for setting documentType is skipped, but the documentMode is needed later.
        // The documentMode is set now to prevent unexpected behavior.
        if mode == .photo {
            newDocument.type.mode = .photo
        }
        
        guard let firstStep = steps.first else { return nil }
        self.currentStep = firstStep
        
        super.init(window: window, navigationController: navigationController)
    }
    
    // MARK: Interface
    func begin() {
        showCurrentStep()
    }
    
    // MARK: Helepers
    private let database: Database = try! Realm()
    private let networkManager: NetworkManager = IkemNetworkManager(api: NativeAPI())
    
    private func showCurrentStep() {
        switch currentStep {
        case .folder:
            showFolderSelectionScreen()
        case .documentType:
            showDocumentTypeSelectionScreen()
        case .photos:
            showPhotosSelectionScreen()
        }
    }
    
    private func showFolderSelectionScreen() {
        let viewModel = NewDocumentFolderViewModel(database: database, networkManager: networkManager)
        let viewController = NewDocumentFolderViewController(viewModel: viewModel, coordinator: self)
        push(viewController)
    }
    
    private func showDocumentTypeSelectionScreen() {
        let viewModel = NewDocumentTypeViewModel(documentMode: mode, database: database)
        let viewController = NewDocumentTypeViewController(viewModel: viewModel, coordinator: self)
        push(viewController)
    }
    
    private func showPhotosSelectionScreen() {
        let viewModel = NewDocumentPhotosViewModel()
        let viewController = NewDocumentPhotosViewController(viewModel: viewModel, coordinator: self)
        push(viewController)
    }
    
    private func showListItemSelectionScreen<T: ListItem>(for list: ListPickerField<T>) {
        let viewController = ListItemSelectionViewController(viewModel: list, coordinator: self)
        push(viewController)
    }
    
    private func finish() {

        let databaseDocument = DocumentDatabaseModel(document: newDocument)
        database.saveObject(databaseDocument)
        
        let documentViewModel = DocumentViewModel(document: newDocument)
        documentViewModel.uploadDocument(with: networkManager)
        
        popAll()
        flowDelegate.newDocumentCreated(documentViewModel)
        flowDelegate.coordinatorDidFinish(self)
    }
    
    private func resolveNextStep() {
        guard let index = steps.firstIndex(of: currentStep) else {
            fatalError("Current step is not present in list of steps")
        }
        
        let nextIndex = index + 1
        
        if nextIndex >= steps.count {
            finish()
            return
        }
        
        currentStep = steps[nextIndex]
        showCurrentStep()
    }
    
    private func savePagesToDocument(_ pages: [UIImage]) {
        
        // Get documents directory
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        
        // Create folder for document
        let folderPath = documentsPath + "/" + newDocument.id
        if !FileManager.default.fileExists(atPath: folderPath) {
            do {
                try FileManager.default.createDirectory(atPath: folderPath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                return
            }
        }
        
        // Store images
        pages
            .compactMap({
                $0.jpegData(compressionQuality: 0.8)
            })
            .enumerated()
            .forEach({ (index, imageData) in
                let fileName = URL(fileURLWithPath: folderPath + "/\(index).jpg")
                if (try? imageData.write(to: fileName)) != nil {
                    newDocument.pages.append(fileName)
                }
            })
        }
    
    private static func steps(for mode: DocumentMode) -> [Step] {
        switch mode {
            case .document, .examination:
                return [.folder, .documentType, .photos]
            case .photo: 
                return [.folder, .photos]
            case .undefined:
                return []
        }
    }
}

// MARK: - NewDocumentTypeCoordinator implementation
extension NewDocumentCoordinator: NewDocumentFolderCoordinator {
    func showNextStep() {
        resolveNextStep()
    }
    
    func saveFolder(_ folder: FolderDomainModel) {
        newDocument.folder = folder
        let databaseFolder = FolderDatabaseModel(folder: folder)
        FolderDatabaseModel.updateLastUsage(of: databaseFolder)
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

// MARK: - ListItemSelectionCoordinator implementation
extension NewDocumentCoordinator: NewDocumentPhotosCoordinator {
    func savePhotos(_ photos: [UIImage]) {
        savePagesToDocument(photos)
    }
}
