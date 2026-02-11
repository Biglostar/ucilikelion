//
//  PaymentRail.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/1/26.
//

import Foundation

enum PaymentRail: String, CaseIterable, Identifiable, Codable, Hashable {
    case unknown
    case debit
    case credit

    var id: String { rawValue }

    var titleKR: String {
        switch self {
        case .unknown: return "알 수 없음"
        case .debit: return "Debit"
        case .credit: return "Credit"
        }
    }
}
