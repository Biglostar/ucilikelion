//
//  SpendProgressCard.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/22/26.
//

import SwiftUI

struct SpendProgressCard: View {
    let spentCents: Int
    let budgetCents: Int

    // MARK: UI constants
    private let barHeight: CGFloat = 30

    var body: some View {
        let remaining = max(budgetCents - spentCents, 0)
        let over = max(spentCents - budgetCents, 0)

        let raw = (budgetCents == 0) ? 0 : Double(spentCents) / Double(budgetCents)
        let progress = max(raw, 0)
        let isFull = progress >= 1.0
        let fillRatio: CGFloat = isFull ? 1 : CGFloat(1 - min(progress, 1))

        let fillColor = isFull ? Theme.minus : Theme.progressFill
        let bgColor   = isFull ? Theme.overBG : Theme.progressBG

        VStack(spacing: Theme.spacingCompact) {

            // MARK: - Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(bgColor)
                        .frame(height: barHeight)

                    Capsule()
                        .fill(fillColor)
                        .frame(
                            width: fillRatio * geo.size.width,
                            height: barHeight
                        )
                        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: fillRatio)
                }
            }
            .frame(height: barHeight)

            Text(isFull ? "\(usd(over)) 초과했어요" : "\(usd(remaining)) 남았어요")
                .font(.custom(Theme.fontLaundry, size: 18))
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Money helper
    private func usd(_ cents: Int) -> String {
        Money.usdSignedString(fromCents: cents).replacingOccurrences(of: "+", with: "")
    }
}
