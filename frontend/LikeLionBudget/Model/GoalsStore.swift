//
//  GoalsStore.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//


import Foundation
import Combine

@MainActor
final class GoalsStore: ObservableObject {

    @Published var goals: [Goal] = [] {
        didSet { save() }
    }

    private let key = "LikeLionBudget.Goals.v1"

    init() {
        if let loaded = Self.load(key: key) {
            self.goals = loaded
        } else {
            self.goals = Self.seedGoals
            save()
        }
    }
    // 홈에 표시되는 목표들
    var selectedGoals: [Goal] {
        goals.filter { $0.isSelected }
    }

    func goal(by id: UUID) -> Goal? {
        goals.first(where: { $0.id == id })
    }

    // 목표 단일 토글
    func setEnabled(_ isOn: Bool, for goalId: UUID) {
        guard let idx = goals.firstIndex(where: { $0.id == goalId }) else { return }
        goals[idx].isSelected = isOn
        goals[idx].isNotificationsOn = isOn
    }

    func setAllNotificationsEnabled(_ isOn: Bool) {
        for i in goals.indices {
            goals[i].isNotificationsOn = isOn
            // 원하면 여기서 홈 표시까지 같이 끄는 정책도 가능:
            // goals[i].isSelected = isOn
        }
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(goals)
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

    // MARK: - Seed

    private static var seedGoals: [Goal] {
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
                title: "카페비 줄이기",
                type: .reduceSpending,
                isSelected: true,
                isNotificationsOn: true,
                statusText: "커피 그만~",
                category: .cafe
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
