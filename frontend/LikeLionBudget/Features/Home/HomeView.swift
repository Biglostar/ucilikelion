//
//  HomeView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import SwiftUI
import UIKit

struct HomeView: View {

    @EnvironmentObject private var onboardingStore: OnboardingStore
    @ObservedObject var store: TransactionStore
    @ObservedObject var goalsStore: GoalsStore
    var aiSpeechMent: String? = nil
    var characterSpendingLevel: Int? = nil

    // MARK: - State

    @State private var selectedGoalID: UUID? = nil
    @State private var month: Date = Date()
    @State private var selectedDayForSheet: SelectedDay? = nil
    @State private var onboardingFrames: [Int: [CGRect]] = [:]
    @State private var tutorialLayoutSeed: Int = 0
    @State private var showOverlayForStep1: Bool = false
    @State private var dashboard: APIClient.DashboardResponse? = nil
    @State private var selectedDashboardGoalIndex: Int = 0

    private var effectiveCharacterLevel: Int {
        if let d = dashboard {
            return Self.characterLevel(from: d.character.status)
        }
        return characterSpendingLevel ?? 0
    }

    private var shouldShowStepOverlay: Bool {
        let step = onboardingStore.currentStep
        return (2...5).contains(step) || (step == 1 && showOverlayForStep1)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Theme.beige.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    homeScrollContent
                }
                .onChange(of: onboardingStore.currentStep) { _, step in
                    handleOnboardingStepChange(step: step, proxy: proxy)
                }
            }
        }
        .onPreferenceChange(OnboardingFramePreferenceKey.self) { value in
            onboardingFrames = value
            onboardingStore.mergeOnboardingFrames(value)
        }
        .onChange(of: onboardingStore.requestOpenDayDetailAt) { _, date in
            if let d = date {
                selectedDayForSheet = SelectedDay(date: d)
                onboardingStore.requestOpenDayDetailAt = nil
            }
        }
        .onChange(of: onboardingStore.currentStep) { _, step in
            if step == 8 { selectedDayForSheet = nil }
            if (1...5).contains(step) { selectedDayForSheet = nil }
        }
        .onAppear {
            if selectedGoalID == nil {
                selectedGoalID = goalsStore.selectedGoals.first?.id
            }
            loadDashboard()
        }
        .overlay {
            if onboardingStore.isTutorialActive && onboardingStore.currentStep == 0 {
                PreTutorialWelcomeOverlay(onStart: {
                    withAnimation(.easeInOut(duration: 0.25)) { onboardingStore.advance() }
                })
                .ignoresSafeArea()
            }
        }
        .onChange(of: onboardingStore.currentStep) { _, newStep in
            if newStep == 1 {
                showOverlayForStep1 = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { tutorialLayoutSeed += 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { tutorialLayoutSeed += 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) { tutorialLayoutSeed += 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { tutorialLayoutSeed += 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.68) { tutorialLayoutSeed += 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.82) { showOverlayForStep1 = true }
            } else {
                showOverlayForStep1 = false
            }
            if (1...5).contains(newStep) && (onboardingStore.collectedOnboardingFrames[newStep] ?? []).isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { tutorialLayoutSeed += 1 }
            }
        }
        .sheet(item: $selectedDayForSheet) { item in
            DayDetailSheetContainer(date: item.date, store: store)
                .environmentObject(onboardingStore)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.white)
                .presentationCornerRadius(Theme.sheetCornerRadius)
        }
    }

    private var homeScrollContent: some View {
        VStack(spacing: 0) {
            headerSection
                .background(Theme.beige)
                .id("onboardingTop")

            VStack(spacing: Theme.Home.gapGoalToCalendar) {
                VStack(spacing: Theme.Home.gapInsideGoalPage) {
                    if let d = dashboard, !d.activeGoals.isEmpty {
                        DashboardGoalPagerView(
                            activeGoals: d.activeGoals,
                            selectedIndex: $selectedDashboardGoalIndex
                        )
                        DashboardGoalRemainingLabel(
                            goal: d.activeGoals[selectedDashboardGoalIndex]
                        )
                    } else {
                        GoalProgressPagerView(
                            goals: goalsStore.selectedGoals,
                            selectedGoalID: $selectedGoalID,
                            store: store,
                            gapInsidePage: Theme.Home.gapInsideGoalPage
                        )
                        GoalRemainingLabel(
                            goals: goalsStore.selectedGoals,
                            selectedGoalID: selectedGoalID,
                            store: store
                        )
                    }
                }
                .onboardingFrame(stepId: 4)

                MonthCalendarView(month: $month, store: store, selectedDay: $selectedDayForSheet)
                    .padding(.vertical, Theme.Home.calendarVerticalPadding)
                    .onboardingFrame(stepId: 5)
                    .id("onboardingCalendar")
            }
            .padding(.horizontal, Theme.Home.goalCalendarHorizontal)
            .padding(.top, Theme.Home.gapHeaderToGoalBlock)
            .padding(.bottom, Theme.screenBottom)
            .background(Color.white)
        }
        .id(tutorialLayoutSeed)
    }

    private func handleOnboardingStepChange(step: Int, proxy: ScrollViewProxy) {
        if step == 5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    proxy.scrollTo("onboardingCalendar", anchor: .center)
                }
            }
        } else if (1...4).contains(step) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    proxy.scrollTo("onboardingTop", anchor: .top)
                }
            }
        }
    }

    // MARK: - Header Section (캐릭터 + 말풍선 + 이번달 지출)

    private var headerSection: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let headerH = Theme.screenHeight * Theme.Home.headerRatio
            let imageH = headerH - Theme.Home.spendAreaHeight
            let layout = HomeBubbleLayout.default(level: effectiveCharacterLevel)

            VStack(spacing: 0) {
                ZStack {
                    Theme.beige

                    Group {
                        if effectiveCharacterLevel == 1 {
                            Image(characterImageName(for: effectiveCharacterLevel))
                                .resizable()
                                .scaledToFit()
                        } else {
                            Image(characterImageName(for: effectiveCharacterLevel))
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    .scaleEffect(effectiveCharacterLevel == 0 ? Theme.Home.characterLevel0Scale : 1.0)
                    .frame(width: w, height: imageH)
                    .clipped()
                    .onboardingFrame(stepId: 3)
                    .overlay {
                        SpeechBubbleView(text: speechTextMonthOnly)
                            .frame(width: w * Theme.Home.bubbleWidthRatio)
                            .fixedSize(horizontal: false, vertical: true)
                            .position(x: w * CGFloat(layout.bubbleX), y: imageH * CGFloat(layout.bubbleY))

                        BubbleTailDots()
                            .position(x: w * CGFloat(layout.tailX), y: imageH * CGFloat(layout.tailY))
                    }
                    .overlay {
                        GeometryReader { overlayGeo in
                            let w = overlayGeo.size.width
                            let h = overlayGeo.size.height
                            let g = overlayGeo.frame(in: .global)
                            let bubbleW = w * Theme.Home.bubbleWidthRatio
                            let bubbleH: CGFloat = 56
                            let bubbleInset: CGFloat = 5
                            let bubbleCutoutW = max(1, bubbleW - bubbleInset * 2)
                            let bubbleCutoutH = max(1, bubbleH - bubbleInset * 2)
                            let bubbleGlobal = CGRect(
                                x: g.minX + w * CGFloat(layout.bubbleX) - bubbleCutoutW / 2,
                                y: g.minY + h * CGFloat(layout.bubbleY) - bubbleCutoutH / 2,
                                width: bubbleCutoutW,
                                height: bubbleCutoutH
                            )
                            let tx = g.minX + w * CGFloat(layout.tailX)
                            let ty = g.minY + h * CGFloat(layout.tailY)
                            let tail1Global = CGRect(x: tx + 4 - 9, y: ty - 5 - 4.5, width: 18, height: 9)
                            let tail2Global = CGRect(x: tx - 9 - 6, y: ty + 5 - 2.5, width: 12, height: 5)
                            Color.clear
                                .preference(key: OnboardingFramePreferenceKey.self, value: [2: [bubbleGlobal, tail1Global, tail2Global]])
                        }
                    }
                }
                .frame(height: imageH)
                .clipped()

                SpendMonthOnlyView(monthAmount: totalSpendTextThisMonth())
                    .frame(height: Theme.Home.spendAreaHeight)
                    .onboardingFrame(stepId: 1)
                    .background(Theme.beige)
            }
            .coordinateSpace(name: "homeHeaderGlobal")
            .frame(height: headerH)
        }
        .frame(height: Theme.screenHeight * Theme.Home.headerRatio)
    }

    // MARK: - Header helpers

    private static let characterImageNames = [
        "Character_level1",
        "Character_level2",
        "Character_level3",
        "Character_level4",
        "Character_level5"
    ]
    private func characterImageName(for level: Int) -> String {
        let index = min(max(level, 0), Self.characterImageNames.count - 1)
        return Self.characterImageNames[index]
    }

    private var speechTextMonthOnly: String {
        if let text = dashboard?.character.bubbleText, !text.isEmpty { return text }
        return aiSpeechMent ?? "뭐함? 개거지\n진짜 망했네"
    }

    // MARK: - Month spend text

    private func totalSpendTextThisMonth() -> String {
        if let d = dashboard {
            return Money.usdSignedString(fromCents: -d.summary.totalMonthSpentCents)
                .replacingOccurrences(of: "-", with: "")
        }
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

    private func loadDashboard() {
        Task {
            do {
                let d = try await APIClient().fetchDashboard()
                await MainActor.run { dashboard = d }
            } catch {
                // 오프라인/백엔드 미동작 시 로컬 계산 유지
            }
        }
    }

    private static func characterLevel(from status: String) -> Int {
        switch status.uppercased() {
        case "RICH": return 0
        case "STABLE": return 1
        case "SURVIVING": return 2
        case "DESPERATE": return 3
        case "BROKE": return 4
        default: return 1
        }
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
            .frame(height: 44)
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

// MARK: - 남았어요 / 초과했어요 라벨

private struct GoalRemainingLabel: View {
    let goals: [Goal]
    let selectedGoalID: UUID?
    @ObservedObject var store: TransactionStore

    var body: some View {
        if let goal = goals.first(where: { $0.id == selectedGoalID }) {
            let budget = budgetCents(for: goal.category)
            let spent = spentCentsThisMonth(for: goal.category)
            let remaining = max(budget - spent, 0)
            let over = max(spent - budget, 0)
            let isOver = over > 0
            Text(isOver ? "\(usd(over)) 초과했어요" : "\(usd(remaining)) 남았어요")
                .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                .foregroundStyle(isOver ? Theme.minus : Theme.text)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    /// 예산 (cents). Dashboard activeGoals 없을 때만 사용. 있으면 API(DashboardActiveGoal.budget) 사용.
    private func budgetCents(for category: BudgetCategory) -> Int {
        switch category {
        case .rent: return 1800 * 100
        case .utilities: return 200 * 100
        case .grocery: return 400 * 100
        case .cafe: return 60 * 100
        case .food: return 250 * 100
        default: return 200 * 100
        }
    }

    /// 이번 달 해당 카테고리 지출 (cents). Dashboard 없을 때만 사용. 있으면 API(DashboardActiveGoal.spent) 사용.
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

// MARK: - Dashboard active goals (API 데이터 사용)

private struct DashboardGoalPagerView: View {
    let activeGoals: [APIClient.DashboardActiveGoal]
    @Binding var selectedIndex: Int

    private let barHeight: CGFloat = 32
    private var goalTitleColor: Color { Theme.text }

    var body: some View {
        VStack(spacing: Theme.Home.gapInsideGoalPage) {
            HStack {
                Button { step(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(goalTitleColor)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                }
                .buttonStyle(.plain)
                .disabled(activeGoals.count <= 1)
                .opacity(activeGoals.count <= 1 ? 0.3 : 1)

                Spacer()

                Text(activeGoals.isEmpty ? "목표 없음" : activeGoals[selectedIndex].title)
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
                .disabled(activeGoals.count <= 1)
                .opacity(activeGoals.count <= 1 ? 0.3 : 1)
            }

            TabView(selection: Binding(
                get: { selectedIndex },
                set: { selectedIndex = $0 }
            )) {
                ForEach(Array(activeGoals.enumerated()), id: \.element.id) { index, goal in
                    DashboardGoalProgressPage(goal: goal)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 44)
        }
        .onAppear {
            if selectedIndex >= activeGoals.count, !activeGoals.isEmpty { selectedIndex = 0 }
        }
    }

    private func step(_ delta: Int) {
        guard activeGoals.count > 1 else { return }
        let newIndex = (selectedIndex + delta + activeGoals.count) % activeGoals.count
        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
            selectedIndex = newIndex
        }
    }
}

private struct DashboardGoalProgressPage: View {
    let goal: APIClient.DashboardActiveGoal
    private let barHeight: CGFloat = 32
    @State private var animatedProgress: Double = 0

    var body: some View {
        let fillRatio = goal.remainingPct / 100.0
        let isOver = goal.isOverBudget
        let fillColor = isOver ? Theme.minus : Theme.progressFill
        let bgColor = isOver ? Theme.overBG : Theme.progressBG

        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(bgColor)
                    .frame(height: barHeight)
                Capsule()
                    .fill(fillColor)
                    .frame(width: CGFloat(animatedProgress) * geo.size.width, height: barHeight)
            }
        }
        .frame(height: barHeight)
        .padding(.horizontal, 2)
        .onAppear {
            animatedProgress = 0
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { animatedProgress = fillRatio }
        }
        .onChange(of: goal.remainingPct) { _, _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { animatedProgress = fillRatio }
        }
    }
}

private struct DashboardGoalRemainingLabel: View {
    let goal: APIClient.DashboardActiveGoal

    var body: some View {
        let amount = goal.remainingAmount
        let isOver = goal.isOverBudget
        let text = isOver ? "\(usd(amount)) 초과했어요" : "\(usd(amount)) 남았어요"
        Text(text)
            .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
            .foregroundStyle(isOver ? Theme.minus : Theme.text)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func usd(_ cents: Int) -> String {
        Money.usdSignedString(fromCents: cents).replacingOccurrences(of: "+", with: "")
    }
}

// MARK: - One goal page (게이지바)

private struct GoalProgressPage: View {
    let goal: Goal
    @ObservedObject var store: TransactionStore
    let gapInsidePage: CGFloat

    private let barHeight: CGFloat = 32
    @State private var animatedProgress: Double = 0

    var body: some View {
        let budget = budgetCents(for: goal.category)
        let spent = spentCentsThisMonth(for: goal.category)
        let target = (budget == 0) ? 0 : Double(spent) / Double(budget)
        let isOver = spent >= budget && budget > 0
        /// 100%에서 시작해 줄어듦. 초과 시 빨간색으로 전체 채움
        let fillRatio: Double = isOver ? 1 : (1 - min(target, 1))
        let fillColor = isOver ? Theme.minus : Theme.progressFill
        let bgColor = isOver ? Theme.overBG : Theme.progressBG

        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(bgColor)
                    .frame(height: barHeight)
                Capsule()
                    .fill(fillColor)
                    .frame(width: CGFloat(animatedProgress) * geo.size.width, height: barHeight)
            }
        }
        .frame(height: barHeight)
        .padding(.horizontal, 2)
        .onAppear {
            animatedProgress = 0
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { animatedProgress = fillRatio }
        }
        .onChange(of: spent) { _, _ in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { animatedProgress = fillRatio }
        }
    }

    // MARK: - Data (Dashboard 없을 때만 사용. 있으면 DashboardGoalProgressPage에서 API 값 사용)

    private func budgetCents(for category: BudgetCategory) -> Int {
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

// MARK: - 튜토리얼 시작 전 환영 화면

private struct PreTutorialWelcomeOverlay: View {
    let onStart: () -> Void

    var body: some View {
        Color.black.opacity(0.80)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: Theme.spacingSection) {
                    Spacer()
                    Text("꼽주머니에 오신 걸 환영해요.")
                        .font(.custom(Theme.fontLaundry, size: Theme.titleSize))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text("실제 연결 전, 데모 데이터를 통해\n앱의 주요 기능을 먼저 확인해보세요.")
                        .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    Spacer()
                    Text("화면 오른쪽을 누르면 다음, 왼쪽을 누르면 이전으로 이동해요.")
                        .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.screenHorizontal)
                    Text("← 이전 | 다음 →")
                        .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("터치하여 시작")
                        .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.bottom, Theme.screenBottom + 72)
                }
                .padding(.horizontal, Theme.screenHorizontal * 2)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onStart)
    }
}
