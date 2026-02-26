//
//  ReportView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//

import SwiftUI

struct ReportView: View {
    @EnvironmentObject private var onboardingStore: OnboardingStore
    @ObservedObject var store: TransactionStore
    @State private var onboardingFrames: [Int: [CGRect]] = [:]

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
                VStack(spacing: Theme.spacingStandard) {

                VStack(spacing: Theme.spacingLarge) {
                    DisclosureCard(
                            title: "월간 리포트",
                            subtitle: monthlyHeaderSubtitle(for: selectedMonth),
                            isExpanded: $isMonthlyExpanded
                        ) {
                            MonthlyReportExpanded(store: store, selectedMonth: $selectedMonth)
                        }
                        .onboardingFrame(stepId: 11)

                        DisclosureCard(
                            title: "고정지출",
                            subtitle: fixedHeaderSubtitle(groups: detectedFixedGroups),
                            isExpanded: $isFixedExpanded
                        ) {
                            FixedCostsExpanded(groups: detectedFixedGroups, expandAll: onboardingStore.currentStep == 12)
                        }
                        .onboardingFrame(stepId: 12)
                    }
                }
                .padding(.horizontal, Theme.screenHorizontal)
                .padding(.top, Theme.screenTop + Theme.screenTopNavExtra)
                .padding(.bottom, Theme.screenBottom)
            }
            .background(Color.white)
            .onPreferenceChange(OnboardingFramePreferenceKey.self) { value in
                onboardingFrames = value
                onboardingStore.mergeOnboardingFrames(value)
            }
            .onAppear {
                let step = onboardingStore.currentStep
                if step == 11 {
                    isMonthlyExpanded = true
                    isFixedExpanded = false
                } else if step == 12 {
                    isMonthlyExpanded = false
                    isFixedExpanded = true
                }
            }
            .onChange(of: onboardingStore.currentStep) { _, step in
                var t = SwiftUI.Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    if step == 11 {
                        isMonthlyExpanded = true
                        isFixedExpanded = false
                    } else if step == 12 {
                        isMonthlyExpanded = false
                        isFixedExpanded = true
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("리포트")
                        .font(.custom(Theme.fontLaundry, size: Theme.titleSize))
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
        VStack(spacing: Theme.spacingRegular) {
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
                .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                .fontWeight(.semibold)
                .foregroundStyle(Theme.text)

            Spacer()

            Button {
                selectedMonth = MockData.usCalendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .font(.caption)
        .foregroundStyle(Theme.text)
        .softDividerBox(corner: Theme.cardCorner)
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

        return HStack(spacing: Theme.spacingStandard) {
            VStack(alignment: .leading, spacing: Theme.spacingTight) {
                Text("지출")
                    .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                    .foregroundStyle(Theme.text)
                Text(usd(s.expenseCents))
                    .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.minus)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: Theme.spacingTight) {
                Text("수입")
                    .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                    .foregroundStyle(Theme.text)
                Text(usd(s.incomeCents))
                    .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.plus)
            }
        }
        .cardStyle(bg: Theme.beige, corner: Theme.cardCorner)
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
    var expandAll: Bool = false
    @State private var expandedIDs: Set<UUID> = []

    var body: some View {
        VStack(spacing: Theme.spacingSmall + 4) {
            ForEach(groups) { g in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandAll || expandedIDs.contains(g.id) },
                        set: { isOn in
                            if !expandAll {
                                if isOn { expandedIDs.insert(g.id) }
                                else { expandedIDs.remove(g.id) }
                            }
                        }
                    )
                ) {
                    VStack(spacing: 0) {
                        ForEach(g.items) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: Theme.spacingTight) {
                                    Text(item.title)
                                        .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Theme.text)

                                    if let due = item.dueDay {
                                        Text("결제일(추정): 매월 \(due)일")
                                            .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                                            .foregroundStyle(Theme.text.opacity(0.65))
                                    }
                                }

                                Spacer()

                                Text(usd(item.amountCents))
                                    .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Theme.minus)
                            }
                            .padding(.vertical, Theme.spacingSmall + 4)

                            Divider().opacity(0.25)
                        }
                    }
                } label: {
                    HStack {
                        Text(g.title)
                            .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.text)
                        Spacer()
                        Text(usd(g.totalCents))
                            .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.minus)
                    }
                }
                .cardStyle(bg: Theme.beige, corner: Theme.cardCorner)
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
        VStack(spacing: Theme.spacingRegular) {
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: Theme.spacingSmall + 4) {
                    VStack(alignment: .leading, spacing: Theme.spacingTight) {
                        Text(title)
                            .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                            .foregroundStyle(Theme.text)
                        Text(subtitle)
                            .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                            .foregroundStyle(Theme.text.opacity(0.65))
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.body.weight(.semibold))
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
        .cardStyle(bg: Theme.beige, corner: Theme.cardCorner)
    }
}

struct ChartPlaceholderCard: View {
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSmall + 4) {
            Text(title)
                .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                .foregroundStyle(Theme.text)

            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .fill(Color.clear)
                .frame(height: Theme.chartPlaceholderHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                        .stroke(Color.black.opacity(Theme.strokeOpacityBorder))
                )
                .overlay(
                    VStack(spacing: Theme.spacingTight) {
                        Image(systemName: "chart.pie")
                            .font(.caption)
                            .foregroundStyle(Theme.text.opacity(0.6))
                        Text("차트 연결 예정")
                            .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                            .foregroundStyle(Theme.text.opacity(0.6))
                    }
                )
        }
        .cardStyle(bg: Theme.beige, corner: Theme.cardCorner)
    }
}

struct AIFeedbackMiniCard: View {
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSmall + 4) {
            Text("AI 소비 총평")
                .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                .foregroundStyle(Theme.text)

            Text(text)
                .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                .foregroundStyle(Theme.text.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .softDividerBox(corner: Theme.cardCorner)
        }
        .cardStyle(bg: Theme.beige, corner: Theme.cardCorner)
    }
}

struct MonthlySummary {
    let incomeCents: Int
    let expenseCents: Int
}
