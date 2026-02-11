//
//  ReportView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//

import SwiftUI

struct ReportView: View {
    @ObservedObject var store: TransactionStore

    @State private var selectedMonth: Date = {
        let cal = MockData.usCalendar
        return cal.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    }()

    @State private var isMonthlyExpanded: Bool = true
    @State private var isFixedExpanded: Bool = false

    private var detectedFixedGroups: [RecurringGroup] {
        RecurringDetector().detect(from: store.transactions)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {

                    VStack(spacing: 14) {
                        DisclosureCard(
                            title: "월간 리포트",
                            subtitle: monthlyHeaderSubtitle(for: selectedMonth),
                            isExpanded: $isMonthlyExpanded
                        ) {
                            MonthlyReportExpanded(store: store, selectedMonth: $selectedMonth)
                        }

                        DisclosureCard(
                            title: "고정지출",
                            subtitle: fixedHeaderSubtitle(groups: detectedFixedGroups),
                            isExpanded: $isFixedExpanded
                        ) {
                            FixedCostsExpanded(groups: detectedFixedGroups)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
            .background(Color.white)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("리포트")
                        .font(.custom(Theme.fontLaundry, size: 26))
                        .foregroundStyle(Theme.rose)
                }
            }
        }
    }

    private func monthlyHeaderSubtitle(for month: Date) -> String {
        let cal = MockData.usCalendar
        let year = cal.component(.year, from: month)
        let m = cal.component(.month, from: month)

        let s = monthlySummary(for: month)
        return "\(year)년 \(m)월 · 지출 \(usd(s.expenseCents))"
    }

    private func fixedHeaderSubtitle(groups: [RecurringGroup]) -> String {
        let total = groups.reduce(0) { $0 + $1.totalCents }
        return "최근 3개월 추정 · 총합 \(usd(total))"
    }

    private func monthlySummary(for month: Date) -> MonthlySummary {
        let cal = MockData.usCalendar
        guard let interval = cal.dateInterval(of: .month, for: month) else {
            return MonthlySummary(incomeCents: 0, expenseCents: 0)
        }

        let txs = store.transactions.filter { $0.date >= interval.start && $0.date < interval.end }
        let income = txs.filter { $0.amountCents > 0 }.reduce(0) { $0 + $1.amountCents }
        let expense = txs.filter { $0.amountCents < 0 }.reduce(0) { $0 + abs($1.amountCents) }

        return MonthlySummary(incomeCents: income, expenseCents: expense)
    }

    private func usd(_ cents: Int) -> String {
        Money.usdSignedString(fromCents: cents).replacingOccurrences(of: "+", with: "")
    }
}

// MARK: - Monthly expanded

struct MonthlyReportExpanded: View {
    @ObservedObject var store: TransactionStore
    @Binding var selectedMonth: Date

    var body: some View {
        VStack(spacing: 12) {
            MonthPickerRow(selectedMonth: $selectedMonth)
            MonthlySummaryMiniCard(store: store, month: selectedMonth)
            ChartPlaceholderCard(title: "카테고리별 비중 (준비중)")
            AIFeedbackMiniCard(text: "AI 소비 총평 (준비중)")
        }
    }
}

struct MonthPickerRow: View {
    @Binding var selectedMonth: Date

    var body: some View {
        HStack {
            Button {
                selectedMonth = MockData.usCalendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(monthTitle(selectedMonth))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.text)

            Spacer()

            Button {
                selectedMonth = MockData.usCalendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .foregroundStyle(Theme.text)
        .softDividerBox(corner: 8)
    }

    private func monthTitle(_ date: Date) -> String {
        let cal = MockData.usCalendar
        let year = cal.component(.year, from: date)
        let month = cal.component(.month, from: date)
        return "\(year)년 \(month)월"
    }
}

struct MonthlySummaryMiniCard: View {
    @ObservedObject var store: TransactionStore
    let month: Date

    var body: some View {
        let s = summary()

        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("지출")
                    .font(.caption)
                    .foregroundStyle(Theme.text)
                Text(usd(s.expenseCents))
                    .font(.headline)
                    .foregroundStyle(Theme.minus)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("수입")
                    .font(.caption)
                    .foregroundStyle(Theme.text)
                Text(usd(s.incomeCents))
                    .font(.headline)
                    .foregroundStyle(Theme.plus)
            }
        }
        .cardStyle(bg: Theme.beige, corner: 8)
    }

    private func summary() -> MonthlySummary {
        let cal = MockData.usCalendar
        guard let interval = cal.dateInterval(of: .month, for: month) else {
            return MonthlySummary(incomeCents: 0, expenseCents: 0)
        }
        let txs = store.transactions.filter { $0.date >= interval.start && $0.date < interval.end }
        let income = txs.filter { $0.amountCents > 0 }.reduce(0) { $0 + $1.amountCents }
        let expense = txs.filter { $0.amountCents < 0 }.reduce(0) { $0 + abs($1.amountCents) }
        return MonthlySummary(incomeCents: income, expenseCents: expense)
    }

    private func usd(_ cents: Int) -> String {
        Money.usdSignedString(fromCents: cents).replacingOccurrences(of: "+", with: "")
    }
}

// MARK: - Fixed costs

struct FixedCostsExpanded: View {
    let groups: [RecurringGroup]
    @State private var expandedIDs: Set<UUID> = []

    var body: some View {
        VStack(spacing: 10) {
            ForEach(groups) { g in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedIDs.contains(g.id) },
                        set: { isOn in
                            if isOn { expandedIDs.insert(g.id) }
                            else { expandedIDs.remove(g.id) }
                        }
                    )
                ) {
                    VStack(spacing: 0) {
                        ForEach(g.items) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.text)

                                    if let due = item.dueDay {
                                        Text("결제일(추정): 매월 \(due)일")
                                            .font(.caption)
                                            .foregroundStyle(Theme.text.opacity(0.65))
                                    }
                                }

                                Spacer()

                                Text(usd(item.amountCents))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.minus)
                            }
                            .padding(.vertical, 10)

                            Divider().opacity(0.25)
                        }
                    }
                } label: {
                    HStack {
                        Text(g.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.text)
                        Spacer()
                        Text(usd(g.totalCents))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.minus)
                    }
                }
                .cardStyle(bg: Theme.beige, corner: 8)
            }
        }
    }

    private func usd(_ cents: Int) -> String {
        Money.usdSignedString(fromCents: cents).replacingOccurrences(of: "+", with: "")
    }
}

// MARK: - Reusable

struct DisclosureCard<Content: View>: View {
    let title: String
    let subtitle: String
    @Binding var isExpanded: Bool
    let content: () -> Content

    var body: some View {
        VStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.custom(Theme.fontLaundry, size: 16))
                            .foregroundStyle(Theme.text)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Theme.text.opacity(0.65))
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundStyle(Theme.text)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cardStyle(bg: Theme.beige, corner: 8)
    }
}

struct ChartPlaceholderCard: View {
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.custom(Theme.fontLaundry, size: 16))
                .foregroundStyle(Theme.text)

            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.clear)
                .frame(height: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.black.opacity(0.07))
                )
                .overlay(
                    VStack(spacing: 6) {
                        Image(systemName: "chart.pie").foregroundStyle(Theme.text.opacity(0.6))
                        Text("차트 연결 예정")
                            .font(.caption)
                            .foregroundStyle(Theme.text.opacity(0.6))
                    }
                )
        }
        .cardStyle(bg: Theme.beige, corner: 8)
    }
}

struct AIFeedbackMiniCard: View {
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI 소비 총평")
                .font(.custom(Theme.fontLaundry, size: 16))
                .foregroundStyle(Theme.text)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.text.opacity(0.8))
                .softDividerBox(corner: 8)
        }
        .cardStyle(bg: Theme.beige, corner: 8)
    }
}

struct MonthlySummary {
    let incomeCents: Int
    let expenseCents: Int
}
