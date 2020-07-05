//
//  BodyDefectCreationViewController.swift
//  zScanner
//
//  Created by Jakub Skořepa on 05/07/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

class BodyDefectCreationViewController: ListItemSelectionViewController<BodyDefectDomainModel> {
    
    private unowned let coordinator: ListItemSelectionCoordinator
    private let viewModel: ListPickerField<BodyDefectDomainModel>
    
    private let bodyPartId: String
    private var fields: [FormField] = [
        TextInputField(title: "newDocument.defectList.newDefectPlaceholder".localized, validator: { $0.isEmpty }),
        ConfirmButton()
    ]
    
    private var addedSection: Int = 0
    
    init(bodyPartId: String, viewModel: ListPickerField<BodyDefectDomainModel>, coordinator: ListItemSelectionCoordinator) {
        self.bodyPartId = bodyPartId
        self.coordinator = coordinator
        self.viewModel = viewModel
        
        super.init(viewModel: viewModel, coordinator: coordinator)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerCell(TextInputTableViewCell.self)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        addedSection = super.numberOfSections(in: tableView)
        return addedSection + 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case addedSection:
            return fields.count
            
        default:
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case addedSection:
            let item = fields[indexPath.row]
            
            switch item {
            case let text as TextInputField:
                let cell = tableView.dequeueCell(TextInputTableViewCell.self)
                cell.setup(with: text)
                return cell
                
            case let button as ConfirmButton:
                let cell = UITableViewCell()
                cell.textLabel?.text = button.title
                return cell
                
            default:
                return UITableViewCell()
            }
            
        default:
            return super.tableView(tableView, cellForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case addedSection:
            return "Nový defekt"
            
        default:
            return super.tableView(tableView, titleForHeaderInSection: section)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case addedSection:
            let item = fields[indexPath.row]
            
            // Remove focus from textField is user select different cell
            tableView.visibleCells.forEach({ ($0 as? TextInputTableViewCell)?.enableSelection() })
            
            switch item {
            case is TextInputField:
                if let cell = tableView.cellForRow(at: indexPath) as? TextInputTableViewCell {
                    cell.enableTextEdit()
                }
            
            case is ConfirmButton:
                let name = (fields[0] as! TextInputField).text.value
                let item = BodyDefectDomainModel(title: name, bodyPartId: bodyPartId)
                viewModel.selected.accept(item)
                coordinator.backButtonPressed(sender: self)
                
            default:
                break
            }
            
        default:
            super.tableView(tableView, didSelectRowAt: indexPath)
        }
    }
}
