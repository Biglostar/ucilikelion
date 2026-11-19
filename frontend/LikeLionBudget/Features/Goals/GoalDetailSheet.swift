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
    @State private var showBudgetSheet = false

    /// 시트가 열린 뒤 서버에서 갱신된 값이 있으면 그것을 사용
    private var liveGoal: Goal { goalsStore.goals.first(where: { $0.id == goal.id }) ?? goal }
    private var budget: Int { liveGoal.monthlyBudgetCents ?? 0 }
    private var spent: Int {
        if let cents = liveGoal.currentSpentCents { return cents }
        // 예전 캐시 호환: 정수 %에서 역산 (1% 미만 지출은 0이 됨)
        guard let spentPct = liveGoal.spentPct, budget > 0 else { return 0 }
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
            .sheet(isPresented: $showBudgetSheet) {
                SetBudgetSheet(goal: liveGoal, goalsStore: goalsStore)
                    .presentationDetents([.height(300)])
                    .presentationCornerRadius(Theme.sheetCornerRadius)
            }
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

            if budget == 0 {
                // 최근 3개월 지출이 없어 예산이 자동으로 0원 — 사용자가 직접 설정
                Button {
                    showBudgetSheet = true
                } label: {
                    Text("예산 설정하기")
                        .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.progressFill)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
                }
            } else {
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

// MARK: - 예산 입력 시트 (예산이 0원인 목표에 사용자가 직접 설정)

struct SetBudgetSheet: View {
    let goal: Goal
    @ObservedObject var goalsStore: GoalsStore
    @Environment(\.dismiss) private var dismiss

    @State private var dollarsText: String = ""
    @State private var saving = false
    @State private var errorText: String? = nil

    /// 입력한 달러 금액을 센트(정수)로 변환. 0 이하/빈값/비정상이면 nil.
    private var cents: Int? {
        let cleaned = dollarsText
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let dollars = Double(cleaned), dollars > 0 else { return nil }
        return Int((dollars * 100).rounded())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.spacingStandard) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(goal.title)
                        .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                        .foregroundStyle(Theme.text)
                    Text("이 목표의 월 예산을 설정해 주세요")
                        .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                        .foregroundStyle(Theme.text.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    Text("$")
                        .font(.custom(Theme.fontLaundry, size: Theme.titleSize))
                        .foregroundStyle(Theme.text.opacity(0.7))
                    TextField("0", text: $dollarsText)
                        .keyboardType(.decimalPad)
                        .font(.custom(Theme.fontLaundry, size: Theme.titleSize))
                        .foregroundStyle(Theme.text)
                }
                .padding(Theme.cardPadding)
                .background(Theme.beige)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))

                if let errorText {
                    Text(errorText)
                        .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                        .foregroundStyle(Theme.minus)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 0)

                Button {
                    Task { await save() }
                } label: {
                    Text(saving ? "저장 중…" : "저장")
                        .font(.custom(Theme.fontLaundry, size: 16))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.buttonVerticalPadding)
                        .background(cents == nil ? Theme.progressFill.opacity(0.4) : Theme.progressFill)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
                }
                .disabled(cents == nil || saving)
            }
            .padding(.horizontal, Theme.screenHorizontal)
            .padding(.top, Theme.spacingSection)
            .padding(.bottom, Theme.screenBottom)
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("예산 설정")
                        .font(.custom(Theme.fontLaundry, size: Theme.titleSize))
                        .foregroundStyle(Theme.rose)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                        .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                        .foregroundStyle(Theme.rose)
                }
            }
            .tint(Theme.rose)
        }
    }

    private func save() async {
        guard let cents else { return }
        saving = true
        errorText = nil
        let err = await goalsStore.setBudget(goalId: goal.id, cents: cents)
        saving = false
        if let err {
            errorText = err
        } else {
            dismiss()
        }
    }
}
