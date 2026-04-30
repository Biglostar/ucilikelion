//
//  RecurringDetector.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/27/26.
//

import Foundation

struct RecurringItem: Identifiable {
    let id = UUID()
    var title: String
    var amountCents: Int
    var dueDay: Int?
    var confidence: Double
}

struct RecurringGroup: Identifiable {
    let id = UUID()
    var title: String
    var items: [RecurringItem]
    var isExpanded: Bool = false

    var totalCents: Int { items.reduce(0) { $0 + $1.amountCents } }
}

struct RecurringDetector {

    struct Config {
        var monthsBack: Int = 3
        var minOccurrences: Int = 2
        var amountToleranceRatio: Double = 0.10
    }

    let config: Config

    init(config: Config = .init()) {
        self.config = config
    }

    func detect(from transactions: [Transaction], calendar: Calendar = MockData.usCalendar) -> [RecurringGroup] {
        let now = Date()
        guard let start = calendar.date(byAdding: .month, value: -config.monthsBack, to: now) else {
            return []
        }
        let recent = transactions.filter { $0.date >= start && $0.date <= now }

        let expenses = recent.filter { $0.amountCents < 0 }

        let grouped = Dictionary(grouping: expenses) { tx in
            normalizeKey(tx.merchant ?? tx.title)
        }

        var items: [RecurringItem] = []

        for (key, txs) in grouped {
            guard txs.count >= config.minOccurrences else { continue }

            let amounts = txs.map { abs($0.amountCents) }.sorted()
            let repAmount = median(amounts)

            let withinTol = txs.filter {
                let a = Double(abs($0.amountCents))
                let r = Double(repAmount)
                return abs(a - r) <= r * config.amountToleranceRatio
            }

            guard withinTol.count >= config.minOccurrences else { continue }

            let days = withinTol.map { calendar.component(.day, from: $0.date) }
            let due = mode(days)

            let ratio = Double(withinTol.count) / Double(txs.count)
            let monthSpread = Set(withinTol.map { calendar.component(.month, from: $0.date) }).count
            let spreadFactor = min(1.0, Double(monthSpread) / Double(max(1, config.monthsBack)))
            let confidence = max(0.0, min(1.0, ratio * 0.7 + spreadFactor * 0.3))

            let displayName = prettify(key)

            items.append(
                RecurringItem(
                    title: displayName,
                    amountCents: repAmount,
                    dueDay: due,
                    confidence: confidence
                )
            )
        }

        let groupedByCategory = Dictionary(grouping: items) { item in
            categorize(item.title)
        }

        var result: [RecurringGroup] = groupedByCategory.map { (cat, its) in
            RecurringGroup(title: cat, items: its.sorted { $0.amountCents > $1.amountCents })
        }

        result.sort { rank($0.title) < rank($1.title) }

        return result
    }

    // MARK: - Helpers

    private func normalizeKey(_ s: String) -> String {
        let lower = s.lowercased()
        let cleaned = lower
            .replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned
    }

    private func prettify(_ s: String) -> String {
        guard let first = s.first else { return s }
        return String(first).uppercased() + s.dropFirst()
    }

    private func median(_ xs: [Int]) -> Int {
        guard !xs.isEmpty else { return 0 }
        let mid = xs.count / 2
        if xs.count % 2 == 1 { return xs[mid] }
        return (xs[mid - 1] + xs[mid]) / 2
    }

    private func mode(_ xs: [Int]) -> Int? {
        guard !xs.isEmpty else { return nil }
        var freq: [Int: Int] = [:]
        xs.forEach { freq[$0, default: 0] += 1 }
        return freq.sorted { a, b in
            if a.value == b.value { return a.key > b.key }
            return a.value > b.value
        }.first?.key
    }

    private func categorize(_ title: String) -> String {
        let t = title.lowercased()
        if t.contains("rent") || t.contains("utility") || t.contains("internet") || t.contains("electric") {
            return "Rent & Utilities"
        }
        if t.contains("netflix") || t.contains("spotify") || t.contains("youtube") || t.contains("icloud") || t.contains("subscription") || t.contains("hulu") || t.contains("prime") {
            return "Subscription"
        }
        return "기타 고정지출"
    }

    private func rank(_ category: String) -> Int {
        switch category {
        case "Rent & Utilities": return 0
        case "Subscription": return 1
        default: return 9
        }
    }
}
