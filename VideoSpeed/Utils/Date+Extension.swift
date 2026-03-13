//
//  Date+Extension.swift
//  VideoSpeed
//
//  Created by Oren Shalev on 04/02/2026.
//

import Foundation

extension Date {
    static func dateInFuture(days: Int) -> Date {
        return Calendar.current.date(byAdding: .day,
                                     value: days,
                                     to: Date())!
    }

    static func nowWithAppending(seconds: Double) -> Date {
        return Calendar.current.date(byAdding: .second,
                                     value: Int(seconds),
                                     to: Date())!
    }
}
