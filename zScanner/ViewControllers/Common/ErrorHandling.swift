//
//  ErrorHandling.swift
//  zScanner
//
//  Created by Jakub Skořepa on 07/09/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit

protocol ErrorHandling: class {
    func handleError(_ error: RequestError)
    func handleError(_ error: RequestError, okCallback: EmptyClosure?, retryCallback: EmptyClosure?)
}

// MARK: -
extension ErrorHandling where Self: UIViewController {
    
    // MARK: Interface
    func handleError(_ error: RequestError) {
        handleError(error, okCallback: nil, retryCallback: nil)
    }
    
    func handleError(_ error: RequestError, okCallback: EmptyClosure?, retryCallback: EmptyClosure?) {
        let title = "dialog.requestError.title".localized
        let message: String
        
        switch error.type {
        case .serverError(let error):
            message = String(format: "dialog.requestError.message[serverError]".localized, error.localizedDescription)
        case .logicError:
            message = error.message ?? ""
        default:
            message = "dialog.requestError.message[\(error.type.rawValue)]".localized
        }

        let alert = dialog(title: title, message: message)
        
        let okAction = UIAlertAction(
            title: "dialog.requestError.ok".localized,
            style: .default,
            handler: { [unowned self] _ in
                self.dismiss(animated: true, completion: okCallback)
            }
        )
        
        if let retryCallback = retryCallback {
            let retryAction = UIAlertAction(
                title: "dialog.requestError.retry".localized,
                style: .default,
                handler: { [unowned self] _ in
                    self.dismiss(animated: true, completion: retryCallback)
                }
            )
            alert.addAction(retryAction)
        }
        
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: Helpers
    private func dialog(title: String, message: String) -> UIAlertController {
        return UIAlertController(title: title, message: message, preferredStyle: .alert)
    }
}
