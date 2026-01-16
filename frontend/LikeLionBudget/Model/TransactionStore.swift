//
//  TransactionStore.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/14/26.
//

import Foundation
import Combine

@MainActor
final class TransactionStore: ObservableObject {
    @Published private(set) var transactions: [Transaction]
    
    init(seedMonth: Date = Date()) {
        let cal = MockData.usCalendar
        let start = MockData.startOfMonth(seedMonth)
        
        var all: [Transaction] = []
        for offset in 0..<30 {
            if let date = cal.date(byAdding: .day, value: offset, to: start) {
                all.append(contentsOf: MockData.transactions(for: date))
            }
        }
        self.transactions = all
    }
    
    func transactionsForDate(_ date: Date) -> [Transaction] {
        let cal = MockData.usCalendar
        return transactions
            .filter { cal.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }
    
    func netCents(on date: Date) -> Int {
        transactionsForDate(date).reduce(0) { $0 + $1.amountCents }
    }
    
    func addTransaction(date: Date, title: String, amountCents: Int, category: String, merchant: String?) {
        let tx = Transaction(date: date, title: title, amountCents: amountCents, category: category, merchant: merchant)
        transactions.append(tx)
    }
}

