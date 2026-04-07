//
//  TransactionStore.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/14/26.
//
//

import Foundation
import Combine

@MainActor
final class TransactionStore: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []

    private let cal: Calendar = MockData.usCalendar
    private var _realTransactions: [Transaction] = []

    // [백엔드 연동] 발표 후 API 사용 시 아래 주석 해제
    // private let api = APIClient()
    // private var plaidSyncObserver: Any?

    // MARK: - Init / Lifecycle

    init() {
        _realTransactions = MockData.realModeTransactionList()
        transactions = _realTransactions
        // [백엔드 연동] API에서 거래 불러오기:
        // Task { await loadRemoteTransactionsIfNeeded() }
        // plaidSyncObserver = NotificationCenter.default.addObserver(forName: .plaidDidSync, ...) { await self?.loadRemoteTransactionsIfNeeded() }
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
        // [백엔드 연동] POST 후 목록 다시 로드:
        // Task { _ = try? await api.createTransaction(...); await loadRemoteTransactionsIfNeeded() }
    }

    // MARK: - 수정
    func updateTransaction(_ updated: Transaction) {
        guard let idx = _realTransactions.firstIndex(where: { $0.id == updated.id }) else { return }
        _realTransactions[idx] = updated
        _realTransactions.sort { $0.date > $1.date }
        transactions = _realTransactions
    }

    // MARK: - 삭제
    func deleteTransaction(id: UUID) {
        _realTransactions.removeAll { $0.id == id }
        transactions = _realTransactions
        // [백엔드 연동] backendId 있으면: Task { try? await api.deleteTransaction(id: backendId) }
    }

    // MARK: - [백엔드 연동] 아래 메서드들 주석 해제 후 init에서 loadRemote 호출, addTransaction/deleteTransaction에 API 호출 추가
    /*
    private static func parseOccurredAt(_ occurredAt: String) -> Date { ... }
    private func loadRemoteTransactionsIfNeeded() async {
        let backendItems = try await api.fetchTransactions()
        let mapped = backendItems.map { dto in Transaction(...) }
        _realTransactions = mapped.sorted { $0.date > $1.date }
        transactions = _realTransactions
    }
    */
}

// MARK: - Notifications

extension Notification.Name {
    static let plaidDidSync = Notification.Name("plaidDidSync")
}
