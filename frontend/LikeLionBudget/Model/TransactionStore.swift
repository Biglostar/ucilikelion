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
    private var _tutorialTransactions: [Transaction] = []
    private let api = APIClient()
    private weak var onboardingStore: OnboardingStore?
    private var cancellable: AnyCancellable?
    private var plaidSyncObserver: Any?

    // MARK: - Init / Lifecycle

    init() {
        _realTransactions = []
        _tutorialTransactions = Self.buildTutorialMockTransactions()
        transactions = _realTransactions
        Task {
            await loadRemoteTransactionsIfNeeded()
        }
        plaidSyncObserver = NotificationCenter.default.addObserver(
            forName: .plaidDidSync,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.loadRemoteTransactionsIfNeeded()
            }
        }
    }

    deinit {
        if let o = plaidSyncObserver {
            NotificationCenter.default.removeObserver(o)
        }
    }

    // MARK: - Onboarding

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

    // MARK: - Remote Load / Refresh

    private func loadRemoteTransactionsIfNeeded() async {
        guard !showTutorialData else { return }
        do {
            let backendItems = try await api.fetchTransactions()
            let mapped = backendItems.map { dto in
                let amount = dto.type.uppercased() == "EXPENSE" && dto.amountCents > 0
                    ? -dto.amountCents
                    : dto.amountCents
                return Transaction(
                    date: ISO8601DateFormatter().date(from: dto.occurredAt) ?? Date(),
                    title: dto.title,
                    amountCents: amount,
                    category: dto.category,
                    merchant: dto.note,
                    isFixed: dto.isFixed,
                    backendId: dto.id
                )
            }
            _realTransactions = mapped.sorted { $0.date > $1.date }
            transactions = _realTransactions
        } catch {
            print("⚠️ Failed to load transactions from backend:", error)
        }
    }

    // MARK: - 날짜별 거래
    func transactionsForDate(_ date: Date) -> [Transaction] {
        transactions
            .filter { cal.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }

    func netCents(on date: Date) -> Int {
        transactionsForDate(date).reduce(0) { $0 + $1.amountCents         }
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

            Task {
                do {
                    _ = try await api.createTransaction(
                        title: title,
                        amountCents: amountCents,
                        type: amountCents >= 0 ? "INCOME" : "EXPENSE",
                        category: category,
                        occurredAt: date,
                        isFixed: isFixed,
                        note: merchant
                    )
                    await loadRemoteTransactionsIfNeeded()
                } catch {
                    print("⚠️ Failed to post transaction to backend:", error)
                }
            }
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
            // 추후에 백엔드 PUT(수정) 추가되면 다시
        }
    }

    // MARK: - 삭제
    func deleteTransaction(id: UUID) {
        if showTutorialData {
            _tutorialTransactions.removeAll { $0.id == id }
            transactions = _tutorialTransactions
        } else {
            guard let tx = _realTransactions.first(where: { $0.id == id }),
                  let backendId = tx.backendId else {
                _realTransactions.removeAll { $0.id == id }
                transactions = _realTransactions
                return
            }
            _realTransactions.removeAll { $0.id == id }
            transactions = _realTransactions
            Task {
                do {
                    try await api.deleteTransaction(id: backendId)
                } catch {
                    print("⚠️ Failed to delete transaction on backend:", error)
                }
            }
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

// MARK: - Notifications

extension Notification.Name {
    static let plaidDidSync = Notification.Name("plaidDidSync")
}
