//
//  BudgetCategory.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/28/26.
//

import Foundation

enum BudgetCategory: String, CaseIterable, Identifiable, Codable, Hashable {
    case income
    case transportation
    case rent
    case utilities
    case cafe
    case food
    case grocery
    case generalMerchandise
    case personalCare
    case medical
    case entertainment
    case generalServices
    case others

    var id: String { rawValue }

    var displayNameKR: String {
        switch self {
        case .income: return "수입"
        case .transportation: return "교통"
        case .rent: return "월세"
        case .utilities: return "공과금"
        case .cafe: return "카페"
        case .food: return "외식"
        case .grocery: return "식료품"
        case .generalMerchandise: return "잡화"
        case .personalCare: return "개인관리"
        case .medical: return "의료"
        case .entertainment: return "오락"
        case .generalServices: return "서비스"
        case .others: return "기타"
        }
    }

    var emoji: String {
        switch self {
        case .income: return "💸"
        case .transportation: return "🚗"
        case .rent: return "🏠"
        case .utilities: return "⚡️"
        case .cafe: return "☕️"
        case .food: return "🍔"
        case .grocery: return "🛒"
        case .generalMerchandise: return "🛍️"
        case .personalCare: return "🧴"
        case .medical: return "🚑"
        case .entertainment: return "🍿"
        case .generalServices: return "💰"
        case .others: return "🤑"
        }
    }

    var displayLabelKR: String { "\(emoji) \(displayNameKR)" }
}

