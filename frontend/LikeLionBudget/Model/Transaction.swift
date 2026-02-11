//
//  Transaction.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import Foundation

struct Transaction: Identifiable, Hashable, Codable {
    let id: UUID
    var date: Date
    var title: String
    var amountCents: Int
    var category: BudgetCategory
    var merchant: String?
    var isFixed: Bool

    init(
        id: UUID = UUID(),
        date: Date,
        title: String,
        amountCents: Int,
        category: BudgetCategory,
        merchant: String? = nil,
        isFixed: Bool = false
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.amountCents = amountCents
        self.category = category
        self.merchant = merchant
        self.isFixed = isFixed
    }
}
