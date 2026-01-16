//
//  DaySummary.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import Foundation

struct DaySummary: Identifiable, Hashable {
    let id: UUID = UUID()
    let date: Date
    let netCents: Int
}
