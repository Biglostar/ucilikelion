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
    let isSelected: Bool

    private var isToday: Bool {
        MockData.usCalendar.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(dayNumber(date))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.black)

            Text(netText(netCents))
                .font(.caption2)
                .foregroundStyle(netCents >= 0 ? Theme.plus : Theme.minus)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 42)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(borderColor, lineWidth: 1.8)
        )
    }

    private var backgroundColor: Color {
        // 거래 있는 날 배경색
        if netCents != 0 { return Theme.beige }
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

    private func netText(_ cents: Int) -> String {
        if cents == 0 { return "" }
        return Money.usdSignedString(fromCents: cents)
    }
}

