//
//  Goal.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//

import Foundation

// MARK: - GoalType / Goal (목표 모델)

enum GoalType: String, Codable {
    case reduceSpending
    case saveMoney
}

struct Goal: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var type: GoalType
    var isSelected: Bool
    var isNotificationsOn: Bool
    var statusText: String
    var category: BudgetCategory

    init(
        id: UUID = UUID(),
        title: String,
        type: GoalType,
        isSelected: Bool = true,
        isNotificationsOn: Bool = true,
        statusText: String,
        category: BudgetCategory
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.isSelected = isSelected
        self.isNotificationsOn = isNotificationsOn
        self.statusText = statusText
        self.category = category
    }
}
