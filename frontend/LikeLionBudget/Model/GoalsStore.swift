//
//  GoalsStore.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class GoalsStore: ObservableObject {

    @Published private(set) var goals: [Goal] = []

    /// 목표 생성 직후 예산이 0원이면, 예산 입력 시트를 띄우도록 뷰에 신호를 보냄
    @Published var pendingBudgetPromptGoalID: UUID? = nil

    private var _realGoals: [Goal] = []
    private let api = APIClient()
    private let key = "LikeLionBudget.Goals.v1"

    static let tutorialMockGoals: [Goal] = [
        Goal(title: "생활비 줄이기", type: .reduceSpending, isSelected: true, isNotificationsOn: true,
             statusText: "", category: .food, monthlyBudgetCents: 30000, spentPct: 45, remainingPct: 55, overBudget: false),
        Goal(title: "카페 아끼기", type: .reduceSpending, isSelected: true, isNotificationsOn: true,
             statusText: "", category: .cafe, monthlyBudgetCents: 10000, spentPct: 70, remainingPct: 30, overBudget: false)
    ]

    var isTutorialMode: Bool = false {
        didSet { goals = isTutorialMode ? Self.tutorialMockGoals : _realGoals }
    }

    // MARK: - Init

    init() {
        // Start from whatever was cached locally, then refresh from the server
        _realGoals = Self.load(key: key) ?? []
        goals = _realGoals
        Task { await loadRemoteGoals() }
        // Reload goal spending whenever a transaction is created/updated/deleted
        NotificationCenter.default.addObserver(
            forName: .transactionDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.loadRemoteGoals() }
        }
    }

    func reloadFromServer() async {
        await loadRemoteGoals()
    }

    // MARK: - Public Access

    var selectedGoals: [Goal] {
        goals.filter { $0.isSelected }
    }

    func goal(by id: UUID) -> Goal? {
        goals.first(where: { $0.id == id })
    }

    func binding(for goalId: UUID) -> Binding<Goal>? {
        guard let g = goal(by: goalId) else { return nil }
        return Binding(
            get: { [weak self] in self?.goal(by: goalId) ?? g },
            set: { [weak self] in self?.updateGoal($0) }
        )
    }

    // MARK: - Update / Delete / Toggle

    func updateGoal(_ goal: Goal) {
        guard let idx = _realGoals.firstIndex(where: { $0.id == goal.id }) else { return }
        // Preserve backendId and budget fields since the editor rebuilds Goal without them
        let existingBackendId = _realGoals[idx].backendId
        let existingBudget = _realGoals[idx].monthlyBudgetCents
        var enriched = goal
        enriched.backendId = existingBackendId
        if enriched.monthlyBudgetCents == nil { enriched.monthlyBudgetCents = existingBudget }
        // 편집기는 지출 정보 없이 Goal을 새로 만들기 때문에 기존 값을 유지 (안 그러면 지출이 0으로 보임)
        if enriched.currentSpentCents == nil {
            enriched.currentSpentCents = _realGoals[idx].currentSpentCents
            enriched.spentPct = _realGoals[idx].spentPct
            enriched.remainingPct = _realGoals[idx].remainingPct
            enriched.overBudget = _realGoals[idx].overBudget
        }
        _realGoals[idx] = enriched
        goals = _realGoals
        saveRealGoals()

        guard let backendId = existingBackendId else { return }
        Task {
            do {
                try await api.updateGoal(
                    id: backendId,
                    title: goal.title,
                    memo: goal.statusText.isEmpty ? nil : goal.statusText,
                    category: goal.category,
                    monthlyBudgetCents: nil
                )
                // 카테고리가 바뀌면 서버가 지출을 다시 계산하므로 최신 값으로 갱신
                await loadRemoteGoals()
            } catch {
                print("⚠️ updateGoal API failed:", error)
            }
        }
    }

    /// 예산이 0원인 목표에 사용자가 직접 예산을 설정. 성공 시 nil, 실패 시 사용자에게 보여줄 에러 메시지 반환.
    func setBudget(goalId: UUID, cents: Int) async -> String? {
        guard let backendId = _realGoals.first(where: { $0.id == goalId })?.backendId else {
            return "목표를 찾을 수 없어요."
        }
        do {
            try await api.updateGoal(id: backendId, title: nil, memo: nil, category: nil, monthlyBudgetCents: cents)
            await loadRemoteGoals()
            // 홈 대시보드도 갱신되도록 알림 (HomeView가 수신)
            NotificationCenter.default.post(name: .transactionDidChange, object: nil)
            return nil
        } catch APIError.serverStatus(409) {
            // 이미 예산이 설정된 목표 — 최신 상태로 리로드만 하고 성공 처리
            await loadRemoteGoals()
            return nil
        } catch APIError.serverStatus(400) {
            return "올바른 금액을 입력해 주세요."
        } catch {
            print("⚠️ setBudget API failed:", error)
            return "예산 설정에 실패했어요. 잠시 후 다시 시도해 주세요."
        }
    }

    func deleteGoal(id: UUID) {
        let backendId = _realGoals.first(where: { $0.id == id })?.backendId
        _realGoals.removeAll { $0.id == id }
        goals = _realGoals
        saveRealGoals()

        guard let backendId else { return }
        Task {
            do {
                try await api.deleteGoal(id: backendId)
            } catch {
                print("⚠️ deleteGoal API failed:", error)
            }
        }
    }

    func setEnabled(_ isOn: Bool, for goalId: UUID) {
        guard let idx = _realGoals.firstIndex(where: { $0.id == goalId }) else { return }
        _realGoals[idx].isSelected = isOn
        _realGoals[idx].isNotificationsOn = isOn
        goals = _realGoals
        saveRealGoals()
    }

    func setAllNotificationsEnabled(_ isOn: Bool) {
        for i in _realGoals.indices {
            _realGoals[i].isNotificationsOn = isOn
        }
        goals = _realGoals
        saveRealGoals()
    }

    func insertGoal(_ goal: Goal) {
        _realGoals.insert(goal, at: 0)
        goals = _realGoals
        saveRealGoals()
        Task { await postNewGoalToBackend(goal) }
    }

    // MARK: - Persistence

    private func saveRealGoals() {
        do {
            let data = try JSONEncoder().encode(_realGoals)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("⚠️ Goals save failed:", error)
        }
    }

    private static func load(key: String) -> [Goal]? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode([Goal].self, from: data)
        } catch {
            print("⚠️ Goals load failed:", error)
            return nil
        }
    }

    // MARK: - Remote

    private func loadRemoteGoals() async {
        do {
            let backendGoals = try await api.fetchGoals()
            let mapped: [Goal] = backendGoals.map { bg in
                Goal(
                    // 같은 서버 목표는 로컬 id를 유지 (열려 있는 상세 화면이 최신 값을 찾을 수 있도록)
                    id: _realGoals.first(where: { $0.backendId == bg.id })?.id ?? UUID(),
                    title: bg.title,
                    type: .reduceSpending,
                    isSelected: true,
                    isNotificationsOn: true,
                    statusText: bg.memo ?? "",
                    category: bg.category,
                    backendId: bg.id,
                    monthlyBudgetCents: bg.monthlyBudgetCents,
                    spentPct: bg.spentPct,
                    remainingPct: bg.remainingPct,
                    overBudget: bg.overBudget,
                    currentSpentCents: bg.currentSpentCents
                )
            }
            _realGoals = mapped
            if !isTutorialMode { goals = mapped }
            saveRealGoals()
        } catch {
            print("⚠️ fetchGoals API failed:", error)
            // API 실패 시 로컬 캐시도 신뢰하지 않음 — 빈 목록 표시
            _realGoals = []
            if !isTutorialMode { goals = [] }
        }
    }

    private func postNewGoalToBackend(_ goal: Goal) async {
        do {
            let now = Date()
            let bg = try await api.createGoal(
                title: goal.title,
                memo: goal.statusText.isEmpty ? nil : goal.statusText,
                icon: nil,
                category: goal.category,
                startDate: now,
                endDate: now,
                budgetSource: "AUTO_AVG_3M"
            )
            // Store the backend ID on the local goal so future edits/deletes work
            if let idx = _realGoals.firstIndex(where: { $0.id == goal.id }) {
                _realGoals[idx].backendId = bg.id
                _realGoals[idx].monthlyBudgetCents = bg.monthlyBudgetCents
                goals = _realGoals
                saveRealGoals()
            }
            // 생성 직후 서버가 계산한 이번 달 지출/게이지 반영
            await loadRemoteGoals()
            // 최근 3개월 지출이 없어 예산이 0원으로 잡히면, 사용자가 바로 예산을 설정하도록 프롬프트
            if bg.monthlyBudgetCents == 0 {
                pendingBudgetPromptGoalID = goal.id
            }
        } catch {
            print("⚠️ createGoal API failed:", error)
        }
    }
}
