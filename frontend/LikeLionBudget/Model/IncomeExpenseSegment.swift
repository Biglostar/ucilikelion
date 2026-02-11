//
//  IncomeExpenseSegment.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/31/26.
//

import SwiftUI

struct IncomeExpenseSegment: View {
    @Binding var isExpense: Bool

    var body: some View {
        Picker("", selection: $isExpense) {
            Text("지출").tag(true)
            Text("수입").tag(false)
        }
        .pickerStyle(.segmented)
        .tint(.green)
        .labelsHidden()
        .controlSize(.small)
    }
}
