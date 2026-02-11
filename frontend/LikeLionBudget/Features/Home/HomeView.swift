//
//  HomeView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

//
//  HomeView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import SwiftUI

struct HomeView: View {

    @ObservedObject var store: TransactionStore
    @ObservedObject var goalsStore: GoalsStore

    @State private var selectedGoalID: UUID? = nil
    @State private var month: Date = Date()

    private let headerRatio: CGFloat = 0.56
    private let spendAreaHeight: CGFloat = 160

    private let gapHeaderToGoalBlock: CGFloat = 16
    private let gapInsideGoalPage: CGFloat = 12
    private let gapGoalToCalendar: CGFloat = 16
    private let sidePadding: CGFloat = 16
    private let bottomPadding: CGFloat = 28

    private let bubbleX: CGFloat = 0.78
    private let bubbleY: CGFloat = 0.21
    private let tailX: CGFloat   = 0.648
    private let tailY: CGFloat   = 0.335

    var body: some View {
        ZStack {
            Theme.beige.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                        .background(Theme.beige)

                    VStack(spacing: gapGoalToCalendar) {

                        GoalProgressPagerView(
                            goals: goalsStore.selectedGoals,
                            selectedGoalID: $selectedGoalID,
                            store: store,
                            gapInsidePage: gapInsideGoalPage
                        )

                        MonthCalendarView(month: $month, store: store)
                            .padding(.vertical, 4)
                    }
                    .padding(.horizontal, sidePadding)
                    .padding(.top, gapHeaderToGoalBlock)
                    .padding(.bottom, bottomPadding)
                    .background(Color.white)
                }
            }
        }

        .onAppear {
            if selectedGoalID == nil {
                selectedGoalID = goalsStore.selectedGoals.first?.id
            }
        }
    }

    // MARK: - Header Section (캐릭터 + 말풍선 + 이번달 지출)

    private var headerSection: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let headerH = UIScreen.main.bounds.height * headerRatio
            let imageH = headerH - spendAreaHeight

            VStack(spacing: 0) {

                // MARK: Character + bubble area
                ZStack {
                    Theme.beige

                    Image(characterImageName())
                        .resizable()
                        .scaledToFit()
                        .frame(width: w, height: imageH)
                        .clipped()
                        .overlay {
                            SpeechBubbleView(text: speechTextMonthOnly)
                                .frame(width: w * 0.34)
                                .fixedSize(horizontal: false, vertical: true)
                                .position(x: w * bubbleX, y: imageH * bubbleY)

                            BubbleTailDots()
                                .position(x: w * tailX, y: imageH * tailY)
                        }
                }
                .frame(height: imageH)
                .clipped()

                // MARK: Month spend summary
                SpendMonthOnlyView(monthAmount: totalSpendTextThisMonth())
                    .frame(height: spendAreaHeight)
                    .background(Theme.beige)
            }
            .frame(height: headerH)
        }
        .frame(height: UIScreen.main.bounds.height * headerRatio)
    }

    // MARK: - Header helpers

    private func characterImageName() -> String { "Beggar_poor_new" }

    private var speechTextMonthOnly: String {
        "뭐함? 개거지"
    }

    // MARK: - Month spend text

    private func totalSpendTextThisMonth() -> String {
        let cal = MockData.usCalendar
        let now = Date()
        guard let interval = cal.dateInterval(of: .month, for: now) else { return "0" }

        let spendCents = store.transactions
            .filter { $0.date >= interval.start && $0.date < interval.end }
            .filter { $0.amountCents < 0 }
            .reduce(0) { $0 + abs($1.amountCents) }

        return Money.usdSignedString(fromCents: -spendCents)
            .replacingOccurrences(of: "-", with: "")
    }
}

// MARK: - Month only spend view (헤더 하단)

private struct SpendMonthOnlyView: View {
    let monthAmount: String

    var body: some View {
        VStack(spacing: 2) {
            Text("이번 달에")
                .font(.custom(Theme.fontLaundry, size: 16))
                .foregroundStyle(Theme.text)

            Text(monthAmount)
                .font(.custom(Theme.fontLaundry, size: 44))
                .foregroundStyle(Theme.rose)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text("지출했어요")
                .font(.custom(Theme.fontLaundry, size: 18))
                .foregroundStyle(Theme.text)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Goal + Progress (Swipe as one block)

private struct GoalProgressPagerView: View {
    // MARK: Inputs
    let goals: [Goal]
    @Binding var selectedGoalID: UUID?
    @ObservedObject var store: TransactionStore

    // MARK: Layout
    let gapInsidePage: CGFloat

    // MARK: Colors
    private var goalTitleColor: Color { Theme.text }

    // MARK: TabView selection binding
    private var selectionBinding: Binding<UUID?> {
        Binding(
            get: { selectedGoalID ?? goals.first?.id },
            set: { newValue in
                if let id = newValue, goals.contains(where: { $0.id == id }) {
                    selectedGoalID = id
                } else {
                    selectedGoalID = goals.first?.id
                }
            }
        )
    }

    var body: some View {
        VStack(spacing: gapInsidePage) {

            // MARK: Header row (arrows + title)
            HStack {
                Button { step(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(goalTitleColor)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                }
                .buttonStyle(.plain)
                .disabled(goals.count <= 1)
                .opacity(goals.count <= 1 ? 0.3 : 1)

                Spacer()

                Text(currentTitle)
                    .font(.custom(Theme.fontLaundry, size: 18))
                    .foregroundStyle(goalTitleColor)
                    .lineLimit(1)

                Spacer()

                Button { step(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(goalTitleColor)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                }
                .buttonStyle(.plain)
                .disabled(goals.count <= 1)
                .opacity(goals.count <= 1 ? 0.3 : 1)
            }

            // MARK: Pages
            TabView(selection: selectionBinding) {
                ForEach(goals) { g in
                    GoalProgressPage(
                        goal: g,
                        store: store,
                        gapInsidePage: gapInsidePage
                    )
                    .tag(Optional(g.id))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 110)
        }
        .onAppear {
            if selectedGoalID == nil { selectedGoalID = goals.first?.id }
        }
        .onChange(of: goals) { _, newGoals in
            if let id = selectedGoalID, !newGoals.contains(where: { $0.id == id }) {
                selectedGoalID = newGoals.first?.id
            } else if selectedGoalID == nil {
                selectedGoalID = newGoals.first?.id
            }
        }
    }

    // MARK: Helpers
    private var currentIndex: Int {
        guard let id = selectedGoalID,
              let idx = goals.firstIndex(where: { $0.id == id }) else { return 0 }
        return idx
    }

    private var currentTitle: String {
        guard !goals.isEmpty else { return "목표 없음" }
        return goals[currentIndex].title
    }

    private func step(_ delta: Int) {
        guard goals.count > 1 else { return }
        let newIndex = (currentIndex + delta + goals.count) % goals.count
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            selectedGoalID = goals[newIndex].id
        }
    }
}

// MARK: - One goal page (게이지 + 코멘트)

private struct GoalProgressPage: View {
    // MARK: Inputs
    let goal: Goal
    @ObservedObject var store: TransactionStore
    let gapInsidePage: CGFloat

    // MARK: Gauge
    private let barHeight: CGFloat = 32

    @State private var animatedProgress: Double = 0

    var body: some View {
        // MARK: Compute
        let budget = budgetCents(for: goal.category)
        let spent = spentCentsThisMonth(for: goal.category)
        let remaining = max(budget - spent, 0)

        let target = (budget == 0) ? 0 : min(Double(spent) / Double(budget), 1.0)

        // MARK: UI
        VStack(spacing: gapInsidePage) {

            // MARK: Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.progressBG)
                        .frame(height: barHeight)

                    Capsule()
                        .fill(Theme.progressFill)
                        .frame(
                            width: CGFloat(animatedProgress) * geo.size.width,
                            height: barHeight
                        )
                }
            }
            .frame(height: barHeight)
            .onAppear {
                animatedProgress = 0
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    animatedProgress = target
                }
            }
            .onChange(of: spent) { _, _ in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    animatedProgress = target
                }
            }

            // MARK: Comment
            Text("\(usd(remaining)) 남았어요")
                .font(.custom(Theme.fontLaundry, size: 18))
                .foregroundStyle(Theme.text)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 2)
    }

    // MARK: - Data (임시)

    private func budgetCents(for category: BudgetCategory) -> Int {
        // 목표 예산 로직
        switch category {
        case .rent: return 1800 * 100
        case .utilities: return 200 * 100
        case .grocery: return 400 * 100
        case .cafe: return 60 * 100
        case .food: return 250 * 100
        default: return 200 * 100
        }
    }

    private func spentCentsThisMonth(for category: BudgetCategory) -> Int {
        let cal = MockData.usCalendar
        guard let interval = cal.dateInterval(of: .month, for: Date()) else { return 0 }

        return store.transactions
            .filter { $0.date >= interval.start && $0.date < interval.end }
            .filter { $0.amountCents < 0 }
            .filter { $0.category == category }
            .reduce(0) { $0 + abs($1.amountCents) }
    }

    private func usd(_ cents: Int) -> String {
        Money.usdSignedString(fromCents: cents).replacingOccurrences(of: "+", with: "")
    }
}
