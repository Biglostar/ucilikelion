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

    static func withTime(_ date: Date, hour: Int, minute: Int) -> Date {
        let cal = usCalendar
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = hour
        comps.minute = minute
        return cal.date(from: comps) ?? date
    }

    static func monthSummaries(for month: Date) -> [DaySummary] {
        let cal = usCalendar
        let start = startOfMonth(month)

        return (0..<30).compactMap { offset in
            guard let date = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            let day = cal.component(.day, from: date)

            let net: Int
            if day == 1 { net = 250000 }
            else if day % 7 == 0 { net = -6500 }
            else if day % 3 == 0 { net = -650 }
            else if day % 5 == 0 { net = -1899 }
            else { net = 0 }

            return DaySummary(date: date, netCents: net)
        }
    }

    static func transactions(for date: Date) -> [Transaction] {
        let cal = usCalendar
        let day = cal.component(.day, from: date)

        if day == 1 {
            return [
                Transaction(date: withTime(date, hour: 9, minute: 12), title: "Zelle Payment", amountCents: 250000, category: .income, merchant: nil, isFixed: false),
                Transaction(date: withTime(date, hour: 10, minute: 5), title: "Rent", amountCents: -180000, category: .rent, merchant: nil, isFixed: true),
                Transaction(date: withTime(date, hour: 13, minute: 40), title: "Coffee", amountCents: -650, category: .cafe, merchant: "Starbucks", isFixed: false)
            ]
        } else if day % 7 == 0 {
            return [
                Transaction(date: withTime(date, hour: 11, minute: 20), title: "Groceries", amountCents: -6500, category: .grocery, merchant: "Trader Joe's", isFixed: false),
                Transaction(date: withTime(date, hour: 18, minute: 10), title: "Gas", amountCents: -4200, category: .transportation, merchant: "Chevron", isFixed: false)
            ]
        } else {
            return [
                Transaction(date: withTime(date, hour: 8, minute: 55), title: "Coffee", amountCents: -650, category: .cafe, merchant: "Starbucks", isFixed: false),
                Transaction(date: withTime(date, hour: 19, minute: 5), title: "Food", amountCents: -1899, category: .food, merchant: "In-N-Out", isFixed: false)
            ]
        }
    }
}
