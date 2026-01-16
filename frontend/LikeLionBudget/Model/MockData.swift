//
//  MockData.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import Foundation

enum MockData {

    static var usCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US")
        cal.firstWeekday = 1 // Sunday
        return cal
    }

    static func startOfMonth(_ date: Date) -> Date {
        let cal = usCalendar
        let comps = cal.dateComponents([.year, .month], from: date)
        return cal.date(from: comps) ?? date
    }

    static func monthSummaries(for month: Date) -> [DaySummary] {
        let cal = usCalendar
        let start = startOfMonth(month)

        return (0..<30).compactMap { offset in
            guard let date = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            let day = cal.component(.day, from: date)

            let net: Int
            if day == 1 {
                net = 250000  // +$2,500.00
            } else if day % 7 == 0 {
                net = -6500   // -$65.00
            } else if day % 3 == 0 {
                net = -650    // -$6.50
            } else if day % 5 == 0 {
                net = -1899   // -$18.99
            } else {
                net = 0
            }

            return DaySummary(date: date, netCents: net)
        }
    }

    static func transactions(for date: Date) -> [Transaction] {
        let cal = usCalendar
        let day = cal.component(.day, from: date)

        if day == 1 {
            return [
                Transaction(date: date, title: "Zelle Payment", amountCents: 250000, category: "Income", merchant: nil),
                Transaction(date: date, title: "Rent", amountCents: -180000, category: "Rent", merchant: nil),
                Transaction(date: date, title: "Coffee", amountCents: -650, category: "Coffee", merchant: "Starbucks")
            ]
        } else if day % 7 == 0 {
            return [
                Transaction(date: date, title: "Groceries", amountCents: -6500, category: "Groceries", merchant: "Trader Joe's"),
                Transaction(date: date, title: "Gas", amountCents: -4200, category: "Transport", merchant: "Chevron")
            ]
        } else {
            return [
                Transaction(date: date, title: "Coffee", amountCents: -650, category: "Coffee", merchant: "Starbucks"),
                Transaction(date: date, title: "In-N-Out", amountCents: -1899, category: "Food", merchant: "In-N-Out")
            ]
        }
    }
}
