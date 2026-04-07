//
//  ReportView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//

import SwiftUI

struct ReportView: View {
    @ObservedObject var store: TransactionStore

    // MARK: - State

    @State private var selectedMonth: Date = {
        let cal = MockData.usCalendar
        return cal.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    }()

    @State private var isMonthlyExpanded: Bool = false
    @State private var isFixedExpanded: Bool = false

    private var detectedFixedGroups: [RecurringGroup] {
        let cal = MockData.usCalendar
        let fixed = store.transactions.filter { $0.isFixed && $0.amountCents < 0 }
        let byCategory = Dictionary(grouping: fixed) { $0.category }
        return BudgetCategory.allCases
            .filter { byCategory[$0] != nil }
            .map { category in
                let txs = byCategory[category]!
                let keyed = Dictionary(grouping: txs) { "\($0.title)|\(abs($0.amountCents))" }
                let items = keyed.map { _, group in
                    let first = group.first!
                    let days = group.map { cal.component(.day, from: $0.date) }
                    let dueDay = mode(days) ?? days.first
                    return RecurringItem(
                        title: first.title,
                        amountCents: abs(first.amountCents),
                        dueDay: dueDay,
                        confidence: 1.0
                    )
                }
                .sorted { $0.amountCents > $1.amountCents }
                let groupTitle = Self.fixedExpenseCategoryLabel(category)
                return RecurringGroup(title: groupTitle, items: items)
            }
    }

    private func mode(_ values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        var freq: [Int: Int] = [:]
        values.forEach { freq[$0, default: 0] += 1 }
        return freq.max(by: { $0.value < $1.value })?.key
    }

    // MARK: - Body

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

                        DisclosureCard(
                            title: "고정지출",
                            subtitle: fixedHeaderSubtitle(groups: detectedFixedGroups),
                            isExpanded: $isFixedExpanded
                        ) {
                            FixedCostsExpanded(groups: detectedFixedGroups, expandAll: false)
                        }
                    }
                }
                .padding(.horizontal, Theme.screenHorizontal)
                .padding(.top, Theme.screenTop + Theme.screenTopNavExtra)
                .padding(.bottom, Theme.screenBottom)
            }
            .background(Color.white)
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

    private static func fixedExpenseCategoryLabel(_ category: BudgetCategory) -> String {
        switch category {
        case .entertainment: return "구독"
        case .rent: return "월세"
        case .utilities: return "공과금"
        default: return category.displayNameKR
        }
    }

    private func fixedHeaderSubtitle(groups: [RecurringGroup]) -> String {
        let total = groups.reduce(0) { $0 + $1.totalCents }
        return "총합 \(usd(total))"
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

    private static var maxSelectableMonth: Date {
        let cal = MockData.usCalendar
        let now = Date()
        return cal.date(byAdding: .month, value: -1, to: now) ?? now
    }

    private var categoryBreakdown: [(category: BudgetCategory, cents: Int)] {
        let cal = MockData.usCalendar
        guard let interval = cal.dateInterval(of: .month, for: selectedMonth) else { return [] }
        let expenses = store.transactions
            .filter { $0.date >= interval.start && $0.date < interval.end && $0.amountCents < 0 }
        let byCat = Dictionary(grouping: expenses) { $0.category }
        return BudgetCategory.allCases
            .compactMap { cat in
                guard let txs = byCat[cat], !txs.isEmpty else { return nil }
                let total = txs.reduce(0) { $0 + abs($1.amountCents) }
                return (cat, total)
            }
            .filter { $0.cents > 0 }
            .sorted { $0.cents > $1.cents }
    }

    private var totalExpenseCents: Int {
        categoryBreakdown.reduce(0) { $0 + $1.cents }
    }

    private var totalIncomeCents: Int {
        let cal = MockData.usCalendar
        guard let interval = cal.dateInterval(of: .month, for: selectedMonth) else { return 0 }
        return store.transactions
            .filter { $0.date >= interval.start && $0.date < interval.end && $0.amountCents > 0 }
            .reduce(0) { $0 + $1.amountCents }
    }

    private var aiFeedbackText: String {
        Self.buildFeedback(incomeCents: totalIncomeCents, expenseCents: totalExpenseCents, breakdown: categoryBreakdown)
    }

    private static func buildFeedback(incomeCents: Int, expenseCents: Int, breakdown: [(category: BudgetCategory, cents: Int)]) -> String {
        let income = incomeCents
        let expense = expenseCents
        let top = breakdown.first
        let topPct = expense > 0 && top != nil ? Double(top!.cents) / Double(expense) * 100 : 0
        let pctOfIncome = income > 0 ? Double(expense) / Double(income) * 100 : 0
        let usd: (Int) -> String = { c in
            let d = Double(abs(c)) / 100.0
            if d >= 1000 { return String(format: "$%.0f", d) }
            if d >= 1 { return String(format: "$%.0f", d) }
            return String(format: "$%.2f", d)
        }
        if expense == 0 { return "이번 달엔 한 푼도 안 썼네. 대단한데, 다음 달도 이렇게만 해." }
        var parts: [String] = []
        if income > 0 {
            if expense > income { parts.append("수입은 \(usd(income)) 벌었는데 지출이 \(usd(expense))나 나갔어.") }
            else { parts.append("수입 \(usd(income)) 벌고 \(usd(expense)) 썼어.") }
            let pct = Int(pctOfIncome)
            if pct >= 70 { parts.append("수입의 \(pct)%가 그냥 나간 거라 저축은 어디 가고.") }
        } else {
            parts.append("수입 없이 \(usd(expense))나 썼네. 어디서 나간 거야.")
        }
        if let t = top, topPct >= 25 {
            let names = breakdown.prefix(2).map(\.category.displayNameKR).joined(separator: "·")
            parts.append("지출 중 \(Int(topPct))%가 \(names)로 나가서 \(t.category.displayNameKR)부터 줄이는 게 좋겠어.")
        }
        if top?.category == .cafe || top?.category == .food { parts.append("배달 앱 내려놓고 마트나 한번 가 봐.") }
        else if top?.category == .entertainment { parts.append("구독부터 정리하고 밖에나 나가.") }
        else if expense > income && income > 0 { parts.append("이대로면 다음 달에도 통장이 울어.") }
        return parts.joined(separator: " ")
    }

    var body: some View {
        VStack(spacing: Theme.spacingRegular) {
            MonthPickerRow(selectedMonth: $selectedMonth, maxMonth: Self.maxSelectableMonth)
            MonthlySummaryMiniCard(store: store, month: selectedMonth)
            CategoryPieChartView(store: store, month: selectedMonth, breakdown: categoryBreakdown)
            AIFeedbackMiniCard(text: aiFeedbackText)
        }
    }

}

// MARK: - 카테고리별 비중 파이차트 
struct CategoryPieChartView: View {
    @ObservedObject var store: TransactionStore
    let month: Date
    let breakdown: [(category: BudgetCategory, cents: Int)]
    @State private var showFullChart = false

    private static let sliceColors: [Color] = [
        Theme.minus,
        Theme.progressFill,
        Theme.rose,
        Color(llHex: "#6B8E9F"),
        Color(llHex: "#E8A75C"),
        Color(llHex: "#9B7EBD"),
        Theme.text.opacity(0.7)
    ]

    private var totalCents: Int { breakdown.reduce(0) { $0 + $1.cents } }
    private var slices: [(start: Double, end: Double)] {
        guard totalCents > 0 else { return [] }
        var start: Double = 0
        return breakdown.map { item in
            let ratio = Double(item.cents) / Double(totalCents)
            let end = start + ratio
            let s = (start: start, end: end)
            start = end
            return s
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSmall + 4) {
            Text("카테고리별 비중")
                .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                .foregroundStyle(Theme.text)

            if breakdown.isEmpty {
                Text("이번 달 지출 내역이 없어요")
                    .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                    .foregroundStyle(Theme.text.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
            } else {
                Button {
                    showFullChart = true
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        ZStack {
                            ForEach(Array(slices.enumerated()), id: \.offset) { idx, slice in
                                Circle()
                                    .trim(from: slice.start, to: slice.end)
                                    .stroke(Self.sliceColors[idx % Self.sliceColors.count], lineWidth: 28)
                                    .rotationEffect(.degrees(-90))
                            }
                        }
                        .frame(width: 72, height: 72)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        Text("탭해서 자세히 보기")
                            .font(.custom(Theme.fontLaundry, size: 11))
                            .foregroundStyle(Theme.text.opacity(0.6))
                            .padding(.trailing, Theme.spacingSmall)
                            .padding(.bottom, Theme.spacingSmall)
                    }
                    .frame(minHeight: 88)
                    .padding(.vertical, Theme.spacingSmall)
                }
                .buttonStyle(.plain)
            }
        }
        .cardStyle(bg: Theme.beige, corner: Theme.cardCorner)
        .sheet(isPresented: $showFullChart) {
            CategoryPieChartFullSheet(breakdown: breakdown, onDismiss: { showFullChart = false })
        }
    }
}

private struct CategoryPieChartFullSheet: View {
    let breakdown: [(category: BudgetCategory, cents: Int)]
    let onDismiss: () -> Void

    private static let sliceColors: [Color] = [
        Theme.minus,
        Theme.progressFill,
        Theme.rose,
        Color(llHex: "#6B8E9F"),
        Color(llHex: "#E8A75C"),
        Color(llHex: "#9B7EBD"),
        Theme.text.opacity(0.7)
    ]

    private var totalCents: Int { breakdown.reduce(0) { $0 + $1.cents } }
    private var slices: [(start: Double, end: Double)] {
        guard totalCents > 0 else { return [] }
        var start: Double = 0
        return breakdown.map { item in
            let ratio = Double(item.cents) / Double(totalCents)
            let end = start + ratio
            let s = (start: start, end: end)
            start = end
            return s
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingStandard) {
                    ZStack {
                        ForEach(Array(slices.enumerated()), id: \.offset) { idx, slice in
                            Circle()
                                .trim(from: slice.start, to: slice.end)
                                .stroke(Self.sliceColors[idx % Self.sliceColors.count], lineWidth: 56)
                                .rotationEffect(.degrees(-90))
                        }
                    }
                    .frame(width: 200, height: 200)
                    .padding(.top, 24)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(breakdown.enumerated()), id: \.offset) { idx, item in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Self.sliceColors[idx % Self.sliceColors.count])
                                    .frame(width: 14, height: 14)
                                Text(item.category.displayNameKR)
                                    .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                                    .foregroundStyle(Theme.text)
                                Spacer(minLength: 8)
                                if totalCents > 0 {
                                    Text("\(Int(Double(item.cents) / Double(totalCents) * 100))%")
                                        .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Theme.text)
                                    Text(Self.amountString(item.cents))
                                        .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                                        .foregroundStyle(Theme.text.opacity(0.8))
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(.horizontal, Theme.screenHorizontal)
                    .padding(.top, 20)
                }
            }
            .background(Color.white)
            .navigationTitle("카테고리별 비중")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { onDismiss() }
                        .foregroundStyle(Theme.progressFill)
                }
            }
        }
    }

    private static func amountString(_ cents: Int) -> String {
        let d = Double(abs(cents)) / 100.0
        if d >= 1000 { return String(format: "$%.0f", d) }
        if d >= 1 { return String(format: "$%.0f", d) }
        return String(format: "$%.2f", d)
    }
}

struct MonthPickerRow: View {
    @Binding var selectedMonth: Date
    var maxMonth: Date? = nil

    private var canGoNext: Bool {
        guard let max = maxMonth else { return true }
        let cal = MockData.usCalendar
        let next = cal.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
        let nextStart = cal.date(from: cal.dateComponents([.year, .month], from: next)) ?? next
        let maxStart = cal.date(from: cal.dateComponents([.year, .month], from: max)) ?? max
        return nextStart <= maxStart
    }

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
                guard canGoNext else { return }
                selectedMonth = MockData.usCalendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!canGoNext)
            .opacity(canGoNext ? 1 : 0.35)
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
    @State private var expandedTitles: Set<String> = []

    var body: some View {
        VStack(spacing: Theme.spacingSmall + 4) {
            ForEach(groups) { g in
                let isExpanded = expandAll || expandedTitles.contains(g.title)
                VStack(spacing: 0) {
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                            if expandAll { return }
                            if expandedTitles.contains(g.title) {
                                expandedTitles.remove(g.title)
                            } else {
                                expandedTitles.insert(g.title)
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
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.text.opacity(0.7))
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        }
                    }
                    .buttonStyle(.plain)

                    if isExpanded {
                        VStack(spacing: 0) {
                            ForEach(g.items) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: Theme.spacingTight) {
                                        Text(item.title)
                                            .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Theme.text)

                                        if let due = item.dueDay {
                                            Text("결제일: 매월 \(due)일")
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
                        .padding(.leading, Theme.spacingSmall + 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
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
