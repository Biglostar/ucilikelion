//
//  GoalsStore.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class GoalsStore: ObservableObject {

    @Published private(set) var goals: [Goal] = []

    private var _realGoals: [Goal] = []

    // [백엔드 연동] 발표 후 API 사용 시 아래 주석 해제
    // private let api = APIClient()

    private let key = "LikeLionBudget.Goals.v1"

    // MARK: - Init

    init() {
        _realGoals = Self.load(key: key) ?? Self.defaultRealGoals
        goals = _realGoals
        // [백엔드 연동] API에서 목표 불러오기: Task { await loadRemoteGoalsIfNeeded() }
    }

    private func saveRealGoals() {
        do {
            let data = try JSONEncoder().encode(_realGoals)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("⚠️ Goals save failed:", error)
        }
    }

    // MARK: - Public Access (selectedGoals / goal / binding)

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
        _realGoals[idx] = goal
        goals = _realGoals
        saveRealGoals()
    }

    func deleteGoal(id: UUID) {
        _realGoals.removeAll { $0.id == id }
        goals = _realGoals
        saveRealGoals()
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
        // Task { await postNewGoalToBackend(goal) }
    }

    // MARK: - Persistence

    private static func load(key: String) -> [Goal]? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode([Goal].self, from: data)
        } catch {
            print("⚠️ Goals load failed:", error)
            return nil
        }
    }

    /// 튜토리얼 제거 후 쓰는 기본 목표 (저장된 게 없을 때)
    private static var defaultRealGoals: [Goal] {
        [
            Goal(
                title: "생활비 줄이기",
                type: .reduceSpending,
                isSelected: true,
                isNotificationsOn: true,
                statusText: "이번 달 생활비 줄이자",
                category: .utilities
            ),
            Goal(
                title: "외식비 줄이기",
                type: .reduceSpending,
                isSelected: true,
                isNotificationsOn: true,
                statusText: "외식 대신 집밥",
                category: .food
            ),
            Goal(
                title: "카페비 줄이기",
                type: .reduceSpending,
                isSelected: true,
                isNotificationsOn: true,
                statusText: "",
                category: .cafe
            )
        ]
    }
}
