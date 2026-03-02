//
//  Transaction.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import Foundation

// MARK: - Transaction (거래 모델)

struct Transaction: Identifiable, Hashable, Codable {
    let id: UUID
    var date: Date
    var title: String
    var amountCents: Int
    var category: BudgetCategory
    var merchant: String?
    var isFixed: Bool
    /// 백엔드 거래 id (DELETE /transactions/:id 호출 시 사용)
    var backendId: String?

    init(
        id: UUID = UUID(),
        date: Date,
        title: String,
        amountCents: Int,
        category: BudgetCategory,
        merchant: String? = nil,
        isFixed: Bool = false,
        backendId: String? = nil
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.amountCents = amountCents
        self.category = category
        self.merchant = merchant
        self.isFixed = isFixed
        self.backendId = backendId
    }

    enum CodingKeys: String, CodingKey {
        case id, date, title, amountCents, category, merchant, isFixed, backendId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        title = try c.decode(String.self, forKey: .title)
        amountCents = try c.decode(Int.self, forKey: .amountCents)
        category = try c.decode(BudgetCategory.self, forKey: .category)
        merchant = try c.decodeIfPresent(String.self, forKey: .merchant)
        isFixed = try c.decode(Bool.self, forKey: .isFixed)
        backendId = try c.decodeIfPresent(String.self, forKey: .backendId)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(date, forKey: .date)
        try c.encode(title, forKey: .title)
        try c.encode(amountCents, forKey: .amountCents)
        try c.encode(category, forKey: .category)
        try c.encodeIfPresent(merchant, forKey: .merchant)
        try c.encode(isFixed, forKey: .isFixed)
        try c.encodeIfPresent(backendId, forKey: .backendId)
    }
}
