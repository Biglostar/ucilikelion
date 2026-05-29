//
//  GoalDetailSheet.swift
//  LikeLionBudget
//

import SwiftUI

struct GoalDetailSheet: View {
    let goal: Goal
    @ObservedObject var transactionStore: TransactionStore
    @ObservedObject var goalsStore: GoalsStore
    var onEdit: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var budget: Int { goal.monthlyBudgetCents ?? 0 }
    private var spent: Int {
        guard let spentPct = goal.spentPct, budget > 0 else { return 0 }
        return Int(Double(budget) * spentPct / 100.0)
    }
    private var remaining: Int { max(0, budget - spent) }
    private var fillRatio: Double {
        guard budget > 0 else { return 0 }
        return min(1.0, Double(spent) / Double(budget))
    }
    private var isOver: Bool { spent > budget && budget > 0 }

    private var relatedTransactions: [Transaction] {
        let cal = MockData.usCalendar
        guard let interval = cal.dateInterval(of: .month, for: Date()) else { return [] }
        return transactionStore.transactions
            .filter { $0.category == goal.category }
            .filter { $0.date >= interval.start && $0.date < interval.end }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingStandard) {
                    // 요약 카드
                    summaryCard

                    // 거래 내역
                    if !relatedTransactions.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.spacingRegular) {
                            Text("이번 달 거래 내역")
                                .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                                .foregroundStyle(Theme.text)
                                .padding(.horizontal, Theme.screenHorizontal)

                            VStack(spacing: Theme.spacingTight) {
                                ForEach(relatedTransactions) { tx in
                                    transactionRow(tx)
                                }
                            }
                            .padding(.horizontal, Theme.screenHorizontal)
                        }
                    } else {
                        Text("이번 달 거래 내역이 없어요")
                            .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                            .foregroundStyle(Theme.text.opacity(0.5))
                            .padding(.top, Theme.spacingSection)
                    }
                }
                .padding(.top, Theme.spacingSection)
                .padding(.bottom, Theme.screenBottom)
            }
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(goal.title)
                        .font(.custom(Theme.fontLaundry, size: Theme.titleSize))
                        .foregroundStyle(Theme.rose)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("수정") { onEdit() }
                        .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                        .foregroundStyle(Theme.rose)
                }
            }
            .tint(Theme.rose)
        }
    }

    private var summaryCard: some View {
        VStack(spacing: Theme.spacingRegular) {
            HStack {
                Text(goal.category.emoji)
                    .font(.system(size: 32))
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                        .foregroundStyle(Theme.text)
                    Text(goal.category.displayNameKR)
                        .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                        .foregroundStyle(Theme.text.opacity(0.6))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(Money.usdSignedString(fromCents: spent).replacingOccurrences(of: "+", with: ""))
                        .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                        .foregroundStyle(isOver ? Theme.minus : Theme.text)
                    Text("/ \(Money.usdSignedString(fromCents: budget).replacingOccurrences(of: "+", with: ""))")
                        .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                        .foregroundStyle(Theme.text.opacity(0.6))
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(isOver ? Theme.overBG : Theme.progressBG).frame(height: 10)
                    Capsule().fill(isOver ? Theme.minus : Theme.progressFill)
                        .frame(width: CGFloat(fillRatio) * geo.size.width, height: 10)
                }
            }
            .frame(height: 10)

            HStack {
                Text(isOver ? "예산 초과" : (remaining == 0 ? "예산 완료" : "\(Money.usdSignedString(fromCents: remaining).replacingOccurrences(of: "+", with: "")) 남음"))
                    .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                    .foregroundStyle(isOver ? Theme.minus : Theme.progressFill)
                Spacer()
                Text("월 예산 \(Money.usdSignedString(fromCents: budget).replacingOccurrences(of: "+", with: ""))")
                    .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                    .foregroundStyle(Theme.text.opacity(0.5))
            }
        }
        .padding(Theme.cardPadding)
        .background(Theme.beige)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
            .stroke(Color.black.opacity(0.07), lineWidth: 1))
        .padding(.horizontal, Theme.screenHorizontal)
    }

    private func transactionRow(_ tx: Transaction) -> some View {
        HStack(spacing: Theme.spacingRegular) {
            Text(tx.category.emoji)
                .font(.system(size: 20))
                .frame(width: 36, height: 36)
                .background(Theme.progressBG.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.title)
                    .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                    .foregroundStyle(Theme.text)
                Text(AppFormatters.shortDateTime.string(from: tx.date))
                    .font(.custom(Theme.fontLaundry, size: Theme.captionSmallSize))
                    .foregroundStyle(Theme.text.opacity(0.5))
            }
            Spacer()
            Text(Money.usdSignedString(fromCents: tx.amountCents))
                .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                .foregroundStyle(tx.amountCents < 0 ? Theme.minus : Theme.plus)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, Theme.cardPadding)
        .background(Theme.beige)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
    }
}
