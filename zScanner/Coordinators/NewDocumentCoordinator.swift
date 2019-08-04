//
//  NewDocumentCoordinator.swift
//  zScanner
//
//  Created by Jakub Skořepa on 28/07/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RealmSwift

protocol NewDocumentFlowDelegate: FlowDelegate {}

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
        
        // TODO: Implement
        newDocument.folderId = "1234"
        resolveNextStep()
    }
    
    private func showDocumentTypeSelectionScreen() {
        let viewModel = NewDocumentTypeViewModel(documentMode: mode, database: database)
        let viewController = NewDocumentTypeViewController(viewModel: viewModel, coordinator: self)
        push(viewController)
    }
    
    private func showPhotosSelectionScreen() {
        
        // TODO: Implement
        newDocument.pages = []
        resolveNextStep()
    }
    
    private func finish() {
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
extension NewDocumentCoordinator: NewDocumentTypeCoordinator {}
