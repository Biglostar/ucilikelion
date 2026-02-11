//
//  TransactionStore.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/14/26.
//

import Foundation
import Combine

final class TransactionStore: ObservableObject {
    @Published var transactions: [Transaction] = []

    private let cal: Calendar = MockData.usCalendar

    init() {
        seedMockIfNeeded()
    }

    // MARK: - 날짜별 거래
    func transactionsForDate(_ date: Date) -> [Transaction] {
        transactions
            .filter { cal.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }

    func netCents(on date: Date) -> Int {
        transactionsForDate(date).reduce(0) { $0 + $1.amountCents }
    }

    // MARK: - 추가
    func addTransaction(
        date: Date,
        title: String,
        amountCents: Int,
        category: BudgetCategory,
        merchant: String? = nil,
        isFixed: Bool = false
    ) {
        let tx = Transaction(
            date: date,
            title: title,
            amountCents: amountCents,
            category: category,
            merchant: merchant,
            isFixed: isFixed
        )
        transactions.insert(tx, at: 0)
        transactions.sort { $0.date > $1.date }
    }

    // MARK: - 수정
    func updateTransaction(_ updated: Transaction) {
        guard let idx = transactions.firstIndex(where: { $0.id == updated.id }) else { return }
        transactions[idx] = updated
        transactions.sort { $0.date > $1.date }
    }

    // MARK: - 삭제
    func deleteTransaction(id: UUID) {
        transactions.removeAll { $0.id == id }
    }

    // MARK: - Seed Mock
    private func seedMockIfNeeded() {
        guard transactions.isEmpty else { return }

        let today = Date()
        for offset in 0..<90 {
            guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let mock = MockData.transactions(for: d)
            transactions.append(contentsOf: mock)
        }

        transactions.sort { $0.date > $1.date }
    }
}
