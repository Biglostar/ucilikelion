//
//  DayCellView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import SwiftUI

struct DayCellView: View {
    let date: Date
    let netCents: Int
    let hasTransactions: Bool
    let isSelected: Bool
    var isCurrentMonth: Bool = true

    private var isToday: Bool {
        MockData.usCalendar.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: Theme.spacingTight) {
            Text("\(dayNumber(date))")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isCurrentMonth ? Color.black : Theme.weekdaySimbol)

            if isCurrentMonth, !netText.isEmpty {
                Text(netText)
                    .font(.custom(Theme.fontLaundry, size: Theme.captionSmallSize))
                    .foregroundStyle(netCents >= 0 ? Theme.plus : Theme.minus)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding(.vertical, Theme.spacingSmall)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .stroke(borderColor, lineWidth: Theme.strokeLineWidthCell)
        )
    }

    private var backgroundColor: Color {
        if !isCurrentMonth { return Color.clear }
        if hasTransactions { return Theme.beige }
        return Color.clear
    }

    private var borderColor: Color {
        if isSelected { return Color.green.opacity(0.85) }
        if isToday { return Color.orange.opacity(0.8) }
        return Color.clear
    }

    private func dayNumber(_ date: Date) -> Int {
        MockData.usCalendar.component(.day, from: date)
    }

    private var netText: String {
        if !hasTransactions { return "" }
        return Money.usdSignedString(fromCents: netCents)
    }
}

