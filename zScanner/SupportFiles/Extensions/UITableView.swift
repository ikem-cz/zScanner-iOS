//
//  UITableView.swift
//  zScanner
//
//  Created by Jakub Skořepa on 29/06/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

extension UITableView {
    func cellIdentifier<T: UITableViewCell>(for cellType: T.Type) -> String {
        return String(describing: cellType)
    }
    
    func registerCell<T: UITableViewCell>(_ cellType: T.Type) {
        let name = cellIdentifier(for: cellType)
        register(cellType, forCellReuseIdentifier: name)
    }
    
    func dequeueCell<T: UITableViewCell>(_ cellType: T.Type) -> T {
        // NOTE: This can crash when cell is not registerer for tableview. We want this catch in testing.
        let name = cellIdentifier(for: cellType)
        guard let cell = dequeueReusableCell(withIdentifier: name) as? T else {
            fatalError("You have to register the cell! tableView.register(\(name).self")
        }
        return cell
    }
}
