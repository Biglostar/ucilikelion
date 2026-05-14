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
    @Published private(set) var transactions: [Transaction] = []

    private let cal: Calendar = MockData.usCalendar
    private var _realTransactions: [Transaction] = []
    private let api = APIClient()

    // MARK: - Init

    init() {
        Task { await loadRemoteTransactions() }
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
        _realTransactions.insert(tx, at: 0)
        _realTransactions.sort { $0.date > $1.date }
        transactions = _realTransactions

        Task {
            do {
                let dto = try await api.createTransaction(
                    title: title,
                    amountCents: abs(amountCents),
                    type: amountCents < 0 ? "EXPENSE" : "INCOME",
                    category: category,
                    occurredAt: date,
                    isFixed: isFixed,
                    note: merchant
                )
                if let idx = _realTransactions.firstIndex(where: { $0.id == tx.id }) {
                    _realTransactions[idx].backendId = dto.id
                    transactions = _realTransactions
                }
            } catch {
                print("⚠️ createTransaction failed:", error)
            }
        }
    }

    // MARK: - 수정

    func updateTransaction(_ updated: Transaction) {
        guard let idx = _realTransactions.firstIndex(where: { $0.id == updated.id }) else { return }
        _realTransactions[idx] = updated
        _realTransactions.sort { $0.date > $1.date }
        transactions = _realTransactions

        guard let backendId = updated.backendId else { return }
        Task {
            do {
                _ = try await api.updateTransaction(
                    id: backendId,
                    title: updated.title,
                    amountCents: abs(updated.amountCents),
                    type: updated.amountCents < 0 ? "EXPENSE" : "INCOME",
                    category: updated.category,
                    occurredAt: updated.date,
                    isFixed: updated.isFixed,
                    note: updated.merchant
                )
            } catch {
                print("⚠️ updateTransaction failed:", error)
            }
        }
    }

    // MARK: - 삭제

    func deleteTransaction(id: UUID) {
        guard let tx = _realTransactions.first(where: { $0.id == id }) else { return }
        _realTransactions.removeAll { $0.id == id }
        transactions = _realTransactions

        guard let backendId = tx.backendId else { return }
        Task {
            do {
                try await api.deleteTransaction(id: backendId)
            } catch {
                print("⚠️ deleteTransaction failed:", error)
            }
        }
    }

    // MARK: - Remote Load

    private func loadRemoteTransactions() async {
        do {
            let dtos = try await api.fetchTransactions()
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let mapped: [Transaction] = dtos.map { dto in
                let date = isoFormatter.date(from: dto.occurredAt) ?? Date()
                let cents = dto.type == "EXPENSE" ? -abs(dto.amountCents) : abs(dto.amountCents)
                return Transaction(
                    date: date,
                    title: dto.title,
                    amountCents: cents,
                    category: dto.category,
                    isFixed: dto.isFixed,
                    backendId: dto.id
                )
            }
            _realTransactions = mapped.sorted { $0.date > $1.date }
            transactions = _realTransactions
        } catch {
            print("⚠️ fetchTransactions failed:", error)
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let plaidDidSync = Notification.Name("plaidDidSync")
}