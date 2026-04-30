//
//  Transaction.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import Foundation

struct Transaction: Identifiable, Hashable, Codable {
    let id: String
    let date: Date
    let title: String
    let amountCents: Int
    let category: String
    let merchant: String?
    
    // init(
    //     id: UUID = UUID(),
    //     date: Date,
    //     title: String,
    //     amountCents: Int,
    //     category: String,
    //     merchant: String? = nil
    // ) {
    //     self.id = id
    //     self.date = date
    //     self.title = title
    //     self.amountCents = amountCents
    //     self.category = category
    //     self.merchant = merchant
    // }
}
