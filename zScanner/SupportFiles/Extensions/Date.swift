//
//  Date.swift
//  zScanner
//
//  Created by Jakub Skořepa on 05/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import Foundation

extension Date {

    func round(precision: TimeInterval) -> Date {
        return round(precision: precision, rule: .toNearestOrAwayFromZero)
    }

    func ceil(precision: TimeInterval) -> Date {
        return round(precision: precision, rule: .up)
    }

    func floor(precision: TimeInterval) -> Date {
        return round(precision: precision, rule: .down)
    }

    private func round(precision: TimeInterval, rule: FloatingPointRoundingRule) -> Date {
        let seconds = (self.timeIntervalSinceReferenceDate / precision).rounded(rule) *  precision;
        return Date(timeIntervalSinceReferenceDate: seconds)
    }
}

extension Date {
    
    var utcString: String {
        let dateFormatter = DateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZ")
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        return dateFormatter.string(from: self)
    }
    
    var dateTimeString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: self)
    }
}

private extension DateFormatter {
    convenience init(dateFormat: String) {
        self.init()
        self.dateFormat = dateFormat
    }
}
