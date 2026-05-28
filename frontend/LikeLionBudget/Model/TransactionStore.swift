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
    private var plaidSyncObserver: Any?

    // MARK: - Init / Lifecycle

    init() {
        Task { await loadRemoteTransactions() }
        plaidSyncObserver = NotificationCenter.default.addObserver(
            forName: .plaidDidSync,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.loadRemoteTransactions() }
        }
    }

    deinit {
        if let obs = plaidSyncObserver {
            NotificationCenter.default.removeObserver(obs)
        }
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

        // amountCents is negative for expense, positive for income in local model
        let type = amountCents < 0 ? "EXPENSE" : "INCOME"
        let absAmount = abs(amountCents)
        Task {
            do {
                let bt = try await api.createTransaction(
                    title: title,
                    amountCents: absAmount,
                    type: type,
                    category: category,
                    occurredAt: date,
                    isFixed: isFixed,
                    note: nil
                )
                if let idx = _realTransactions.firstIndex(where: { $0.id == tx.id }) {
                    _realTransactions[idx].backendId = bt.id
                    transactions = _realTransactions
                }
            } catch {
                print("⚠️ createTransaction API failed:", error)
            }
        }
    }

    // MARK: - 수정

    func updateTransaction(_ updated: Transaction) {
        guard let idx = _realTransactions.firstIndex(where: { $0.id == updated.id }) else { return }
        // Preserve backendId since the editor creates a new Transaction without it
        let existingBackendId = _realTransactions[idx].backendId
        var enriched = updated
        enriched.backendId = existingBackendId
        _realTransactions[idx] = enriched
        _realTransactions.sort { $0.date > $1.date }
        transactions = _realTransactions

        guard let backendId = existingBackendId else { return }
        let type = updated.amountCents < 0 ? "EXPENSE" : "INCOME"
        Task {
            do {
                _ = try await api.updateTransaction(
                    id: backendId,
                    title: updated.title,
                    amountCents: abs(updated.amountCents),
                    type: type,
                    category: updated.category,
                    occurredAt: updated.date,
                    isFixed: updated.isFixed,
                    note: nil
                )
            } catch {
                print("⚠️ updateTransaction API failed:", error)
            }
        }
    }

    // MARK: - 삭제

    func deleteTransaction(id: UUID) {
        let backendId = _realTransactions.first(where: { $0.id == id })?.backendId
        _realTransactions.removeAll { $0.id == id }
        transactions = _realTransactions

        guard let backendId else { return }
        Task {
            do {
                try await api.deleteTransaction(id: backendId)
            } catch {
                print("⚠️ deleteTransaction API failed:", error)
            }
        }
    }

    // MARK: - Remote Load

    private func loadRemoteTransactions() async {
        do {
            let backendItems = try await api.fetchTransactions()
            let mapped: [Transaction] = backendItems.map { dto in
                // Backend amountCents is always positive; sign by type for local model
                let localAmount = dto.type == "EXPENSE" ? -dto.amountCents : dto.amountCents
                return Transaction(
                    date: Self.parseDate(dto.occurredAt),
                    title: dto.title,
                    amountCents: localAmount,
                    category: dto.category,
                    isFixed: dto.isFixed,
                    backendId: dto.id
                )
            }
            _realTransactions = mapped.sorted { $0.date > $1.date }
            transactions = _realTransactions
        } catch {
            print("⚠️ fetchTransactions API failed:", error)
            #if DEBUG
            if _realTransactions.isEmpty {
                _realTransactions = MockData.realModeTransactionList()
                transactions = _realTransactions
            }
            #endif
        }
    }

    private static func parseDate(_ occurredAt: String) -> Date {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: occurredAt) { return d }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: occurredAt) ?? Date()
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let plaidDidSync = Notification.Name("plaidDidSync")
}
