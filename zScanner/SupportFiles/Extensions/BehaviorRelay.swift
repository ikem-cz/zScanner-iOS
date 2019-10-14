//
//  BehaviorRelay.swift
//  zScanner
//
//  Created by Martin Georgiu on 16/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import RxRelay

extension BehaviorRelay where Element == Bool {
    func toggle() {
        self.accept(!value)
    }
}
