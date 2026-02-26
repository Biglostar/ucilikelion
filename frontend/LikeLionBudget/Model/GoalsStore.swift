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
    private var _tutorialGoals: [Goal] = []
    private weak var onboardingStore: OnboardingStore?
    private var cancellable: AnyCancellable?

    private let key = "LikeLionBudget.Goals.v1"

    init() {
        _realGoals = Self.load(key: key) ?? []
        _tutorialGoals = Self.tutorialSeedGoals
        goals = _realGoals
    }

    func bindOnboarding(_ store: OnboardingStore) {
        guard onboardingStore == nil else { return }
        onboardingStore = store
        refreshDisplayedGoals()
        cancellable = store.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshDisplayedGoals()
            }
    }

    private var showTutorialData: Bool {
        onboardingStore?.showTutorialSeedData ?? false
    }

    private func refreshDisplayedGoals() {
        if showTutorialData {
            goals = _tutorialGoals
        } else {
            _realGoals = Self.load(key: key) ?? []
            goals = _realGoals
        }
    }

    private func saveRealGoals() {
        do {
            let data = try JSONEncoder().encode(_realGoals)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("⚠️ Goals save failed:", error)
        }
    }
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

    func updateGoal(_ goal: Goal) {
        if showTutorialData {
            guard let idx = _tutorialGoals.firstIndex(where: { $0.id == goal.id }) else { return }
            _tutorialGoals[idx] = goal
            goals = _tutorialGoals
        } else {
            guard let idx = _realGoals.firstIndex(where: { $0.id == goal.id }) else { return }
            _realGoals[idx] = goal
            goals = _realGoals
            saveRealGoals()
        }
    }

    func deleteGoal(id: UUID) {
        if showTutorialData {
            _tutorialGoals.removeAll { $0.id == id }
            goals = _tutorialGoals
        } else {
            _realGoals.removeAll { $0.id == id }
            goals = _realGoals
            saveRealGoals()
        }
    }

    func setEnabled(_ isOn: Bool, for goalId: UUID) {
        if showTutorialData {
            guard let idx = _tutorialGoals.firstIndex(where: { $0.id == goalId }) else { return }
            _tutorialGoals[idx].isSelected = isOn
            _tutorialGoals[idx].isNotificationsOn = isOn
            goals = _tutorialGoals
        } else {
            guard let idx = _realGoals.firstIndex(where: { $0.id == goalId }) else { return }
            _realGoals[idx].isSelected = isOn
            _realGoals[idx].isNotificationsOn = isOn
            goals = _realGoals
            saveRealGoals()
        }
    }

    func setAllNotificationsEnabled(_ isOn: Bool) {
        if showTutorialData {
            for i in _tutorialGoals.indices {
                _tutorialGoals[i].isNotificationsOn = isOn
            }
            goals = _tutorialGoals
        } else {
            for i in _realGoals.indices {
                _realGoals[i].isNotificationsOn = isOn
            }
            goals = _realGoals
            saveRealGoals()
        }
    }

    func insertGoal(_ goal: Goal) {
        if showTutorialData {
            _tutorialGoals.insert(goal, at: 0)
            goals = _tutorialGoals
        } else {
            _realGoals.insert(goal, at: 0)
            goals = _realGoals
            saveRealGoals()
        }
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

    // MARK: - 튜토리얼 전용 시드
    private static var tutorialSeedGoals: [Goal] {
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
                isSelected: false,
                isNotificationsOn: false,
                statusText: "외식 대신 집밥 ㄱ",
                category: .food
            )
        ]
    }
}
