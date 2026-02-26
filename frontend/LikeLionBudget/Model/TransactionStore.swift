//
//  TransactionStore.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/14/26.
//
//

import Foundation
import Combine

final class TransactionStore: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []

    private let cal: Calendar = MockData.usCalendar
    private var _realTransactions: [Transaction] = []
    private var _tutorialTransactions: [Transaction] = []
    private weak var onboardingStore: OnboardingStore?
    private var cancellable: AnyCancellable?

    init() {
        _realTransactions = []
        _tutorialTransactions = Self.buildTutorialMockTransactions()
        transactions = _realTransactions
    }

    func bindOnboarding(_ store: OnboardingStore) {
        guard onboardingStore == nil else { return }
        onboardingStore = store
        refreshDisplayedTransactions()
        cancellable = store.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshDisplayedTransactions()
            }
    }

    private var showTutorialData: Bool {
        onboardingStore?.showTutorialSeedData ?? false
    }

    private func refreshDisplayedTransactions() {
        transactions = showTutorialData ? _tutorialTransactions : _realTransactions
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
        if showTutorialData {
            _tutorialTransactions.insert(tx, at: 0)
            _tutorialTransactions.sort { $0.date > $1.date }
            transactions = _tutorialTransactions
        } else {
            _realTransactions.insert(tx, at: 0)
            _realTransactions.sort { $0.date > $1.date }
            transactions = _realTransactions
        }
    }

    // MARK: - 수정
    func updateTransaction(_ updated: Transaction) {
        if showTutorialData {
            guard let idx = _tutorialTransactions.firstIndex(where: { $0.id == updated.id }) else { return }
            _tutorialTransactions[idx] = updated
            _tutorialTransactions.sort { $0.date > $1.date }
            transactions = _tutorialTransactions
        } else {
            guard let idx = _realTransactions.firstIndex(where: { $0.id == updated.id }) else { return }
            _realTransactions[idx] = updated
            _realTransactions.sort { $0.date > $1.date }
            transactions = _realTransactions
        }
    }

    // MARK: - 삭제
    func deleteTransaction(id: UUID) {
        if showTutorialData {
            _tutorialTransactions.removeAll { $0.id == id }
            transactions = _tutorialTransactions
        } else {
            _realTransactions.removeAll { $0.id == id }
            transactions = _realTransactions
        }
    }

    // MARK: - 튜토리얼 전용 Mock
    private static func buildTutorialMockTransactions() -> [Transaction] {
        let cal = MockData.usCalendar
        var list: [Transaction] = []
        let today = Date()
        for offset in 0..<90 {
            guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            list.append(contentsOf: MockData.transactions(for: d))
        }
        list.sort { $0.date > $1.date }
        return list
    }
}
