//
//  UserSession.swift
//  zScanner
//
//  Created by Jakub Skořepa on 14/09/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

class UserSession {
    
    // MARK: Instance part
    let login: LoginDomainModel
    
    init(login: LoginDomainModel) {
        self.login = login
    }
}
