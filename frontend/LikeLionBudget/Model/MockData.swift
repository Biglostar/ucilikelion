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

    /// 튜토리얼 끝난 뒤 + 리포트용: 2월 전체, 3월 1~10일. 고정지출(월세·구독·전기세) 포함, 항목 다양.
    static func realModeTransactionList() -> [Transaction] {
        let cal = usCalendar
        guard let febStart = cal.date(from: DateComponents(year: 2026, month: 2, day: 1)),
              let marStart = cal.date(from: DateComponents(year: 2026, month: 3, day: 1)) else {
            return []
        }
        var list: [Transaction] = []

        // MARK: - 2월 (1~28일)
        for day in 1...28 {
            guard let date = cal.date(byAdding: .day, value: day - 1, to: febStart) else { continue }
            list.append(contentsOf: realModeTransactions(for: date, month: 2, day: day))
        }

        // MARK: - 3월 1~10일
        for day in 1...10 {
            guard let date = cal.date(byAdding: .day, value: day - 1, to: marStart) else { continue }
            list.append(contentsOf: realModeTransactions(for: date, month: 3, day: day))
        }

        return list.sorted { $0.date > $1.date }
    }

    /// 2월/3월(10일까지)용: 고정지출(월세·넷플·유튜브·스포티파이·전기세) + 수입·외식·카페·식료품·교통·잡화 등
    private static func realModeTransactions(for date: Date, month: Int, day: Int) -> [Transaction] {
        var txs: [Transaction] = []

        // 수입 (매월 1일)
        if day == 1 {
            txs.append(Transaction(date: withTime(date, hour: 9, minute: 0), title: "월급", amountCents: 320000, category: .income, merchant: nil, isFixed: false))
        }

        // 고정지출 — 리포트 "고정지출" 섹션에 나오도록 (RecurringDetector가 2회 이상 동일명/비슷금액으로 묶음)
        if day == 1 {
            txs.append(Transaction(date: withTime(date, hour: 10, minute: 0), title: "Rent", amountCents: -180000, category: .rent, merchant: nil, isFixed: true)) // 월세
        }
        if day == 5 {
            txs.append(Transaction(date: withTime(date, hour: 8, minute: 30), title: "Netflix", amountCents: -1550, category: .entertainment, merchant: "Netflix", isFixed: true))
        }
        if day == 10 {
            txs.append(Transaction(date: withTime(date, hour: 9, minute: 0), title: "YouTube Premium", amountCents: -1299, category: .entertainment, merchant: "YouTube", isFixed: true))
        }
        if day == 15 || (month == 2 && day == 16) {
            txs.append(Transaction(date: withTime(date, hour: 8, minute: 0), title: "Spotify", amountCents: -1099, category: .entertainment, merchant: "Spotify", isFixed: true))
        }
        if day == 20 || (month == 2 && day == 21) {
            txs.append(Transaction(date: withTime(date, hour: 14, minute: 0), title: "Electric", amountCents: -42000, category: .utilities, merchant: nil, isFixed: true)) // 전기세
        }

        // 변동 지출 — 날짜별로 다양하게
        switch day % 10 {
        case 0:
            txs.append(Transaction(date: withTime(date, hour: 11, minute: 20), title: "Groceries", amountCents: -18500, category: .grocery, merchant: "Trader Joe's", isFixed: false))
            txs.append(Transaction(date: withTime(date, hour: 19, minute: 10), title: "Dinner", amountCents: -4200, category: .food, merchant: nil, isFixed: false))
        case 1 where day > 1:
            txs.append(Transaction(date: withTime(date, hour: 8, minute: 45), title: "Coffee", amountCents: -650, category: .cafe, merchant: "Starbucks", isFixed: false))
            txs.append(Transaction(date: withTime(date, hour: 18, minute: 0), title: "Gas", amountCents: -5200, category: .transportation, merchant: nil, isFixed: false))
        case 2:
            txs.append(Transaction(date: withTime(date, hour: 12, minute: 30), title: "Lunch", amountCents: -1500, category: .food, merchant: nil, isFixed: false))
            txs.append(Transaction(date: withTime(date, hour: 20, minute: 0), title: "Pharmacy", amountCents: -3200, category: .personalCare, merchant: nil, isFixed: false))
        case 3:
            txs.append(Transaction(date: withTime(date, hour: 9, minute: 15), title: "Coffee", amountCents: -550, category: .cafe, merchant: nil, isFixed: false))
            txs.append(Transaction(date: withTime(date, hour: 13, minute: 0), title: "Subway", amountCents: -280, category: .transportation, merchant: nil, isFixed: false))
        case 4 where day != 5:
            txs.append(Transaction(date: withTime(date, hour: 19, minute: 0), title: "Dinner", amountCents: -8900, category: .food, merchant: nil, isFixed: false))
        case 5 where day != 5:
            txs.append(Transaction(date: withTime(date, hour: 10, minute: 0), title: "General merchandise", amountCents: -12000, category: .generalMerchandise, merchant: nil, isFixed: false))
        case 6:
            txs.append(Transaction(date: withTime(date, hour: 8, minute: 30), title: "Coffee", amountCents: -650, category: .cafe, merchant: nil, isFixed: false))
            txs.append(Transaction(date: withTime(date, hour: 17, minute: 0), title: "Groceries", amountCents: -7200, category: .grocery, merchant: nil, isFixed: false))
        case 7:
            txs.append(Transaction(date: withTime(date, hour: 12, minute: 0), title: "Lunch", amountCents: -2400, category: .food, merchant: nil, isFixed: false))
            txs.append(Transaction(date: withTime(date, hour: 15, minute: 30), title: "Cafe", amountCents: -450, category: .cafe, merchant: nil, isFixed: false))
        case 8:
            txs.append(Transaction(date: withTime(date, hour: 18, minute: 30), title: "Dinner", amountCents: -5600, category: .food, merchant: nil, isFixed: false))
        case 9:
            txs.append(Transaction(date: withTime(date, hour: 9, minute: 0), title: "Coffee", amountCents: -650, category: .cafe, merchant: nil, isFixed: false))
            txs.append(Transaction(date: withTime(date, hour: 14, minute: 0), title: "Transport", amountCents: -1800, category: .transportation, merchant: nil, isFixed: false))
        default:
            if day % 3 == 0 {
                txs.append(Transaction(date: withTime(date, hour: 8, minute: 50), title: "Coffee", amountCents: -650, category: .cafe, merchant: nil, isFixed: false))
            }
            if day % 7 == 0 {
                txs.append(Transaction(date: withTime(date, hour: 19, minute: 0), title: "Dinner", amountCents: -3500, category: .food, merchant: nil, isFixed: false))
            }
        }

        return txs
    }
}
