//
//  LoginDatabaseModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 15/09/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation
import RealmSwift

class LoginDatabaseModel: Object {
    @objc dynamic var username = ""
    
    convenience init(login: LoginDomainModel) {
        self.init()
        
        self.username = login.username
    }
}

extension LoginDatabaseModel {
    func toDomainModel() -> LoginDomainModel {
        return LoginDomainModel(username: username)
    }
}
