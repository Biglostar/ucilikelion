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
    private let api = APIClient()
    private weak var onboardingStore: OnboardingStore?
    private var cancellable: AnyCancellable?

    private let key = "LikeLionBudget.Goals.v1"

    // MARK: - Init

    init() {
        _realGoals = Self.load(key: key) ?? []
        _tutorialGoals = Self.tutorialSeedGoals
        goals = _realGoals

        Task {
            await loadRemoteGoalsIfNeeded()
        }
    }

    // MARK: - Onboarding

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

    // MARK: - Remote Load / Refresh

    private func loadRemoteGoalsIfNeeded() async {
        guard !showTutorialData else { return }
        do {
            let backendGoals = try await api.fetchGoals()
            let mapped = backendGoals.map { dto in
                Goal(
                    title: dto.title,
                    type: .reduceSpending,
                    isSelected: true,
                    isNotificationsOn: true,
                    statusText: dto.memo ?? "",
                    category: dto.category
                )
            }
            _realGoals = mapped
            goals = _realGoals
            saveRealGoals()
        } catch {
            print("⚠️ Failed to load goals from backend:", error)
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

    // MARK: - Insert (Create) + Backend POST

    func insertGoal(_ goal: Goal) {
        if showTutorialData {
            _tutorialGoals.insert(goal, at: 0)
            goals = _tutorialGoals
        } else {
            _realGoals.insert(goal, at: 0)
            goals = _realGoals
            saveRealGoals()

            Task {
                await postNewGoalToBackend(goal)
            }
        }
    }

    private func postNewGoalToBackend(_ goal: Goal) async {
        let cal = Calendar.current
        guard let start = cal.date(from: cal.dateComponents([.year, .month], from: Date())),
              let end = cal.date(byAdding: DateComponents(month: 1, day: -1), to: start) else { return }
        do {
            _ = try await api.createGoal(
                title: goal.title,
                memo: goal.statusText.isEmpty ? nil : goal.statusText,
                icon: nil,
                category: goal.category,
                monthlyBudgetCents: 0,
                startDate: start,
                endDate: end
            )
            await loadRemoteGoalsIfNeeded()
        } catch {
            print("⚠️ Failed to create goal on backend:", error)
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
