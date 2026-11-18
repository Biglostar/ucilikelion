//
//  MockData.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//
//

import Foundation

enum MockData {

    static var usCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US")
        cal.firstWeekday = 1
        return cal
    }

    static func startOfMonth(_ date: Date) -> Date {
        let cal = usCalendar
        let comps = cal.dateComponents([.year, .month], from: date)
        return cal.date(from: comps) ?? date
    }
}
