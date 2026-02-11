//
//  AddGoalView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//

import SwiftUI

struct AddGoalView: View {
    @ObservedObject var goalsStore: GoalsStore
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var memo: String = ""
    @State private var category: BudgetCategory = .others

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {

                    VStack(spacing: 12) {

                        // 입력 카드
                        VStack(alignment: .leading, spacing: 12) {
                            Text("제목")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.text)

                            TextField("예: 카페비 줄이기", text: $title)
                                .textInputAutocapitalization(.words)

                            Divider().opacity(0.25)

                            Text("메모 (선택)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.text)

                            TextField("예: 이번 달 5번 이하", text: $memo, axis: .vertical)
                                .lineLimit(2...4)
                        }
                        .cardStyle(bg: Theme.beige, corner: 8, strokeOpacity: 0.06, padding: 14)

                        // 카테고리 카드
                        VStack(alignment: .leading, spacing: 10) {
                            Text("목표 카테고리")
                                .font(.custom(Theme.fontLaundry, size: 16))
                                .foregroundStyle(Theme.text)

                            categoryChips
                        }
                        .cardStyle(bg: Color.clear, corner: 8, strokeOpacity: 0.06, padding: 14)

                        // 버튼 카드 (초록)
                        VStack(spacing: 10) {
                            Button { addGoal() } label: {
                                Text("추가하기")
                                    .font(.custom(Theme.fontLaundry, size: 16))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Theme.progressFill)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                        }

                    }
                    .background(Color.clear)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .background(Color.white)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("새로운 목표")
                        .font(.custom(Theme.fontLaundry, size: 26))
                        .foregroundStyle(Theme.rose)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("뒤로") { dismiss() }
                        .foregroundStyle(Theme.text)
                }
            }
        }
    }

    // MARK: - Chips

    private var categoryChips: some View {
        let cols = [GridItem(.adaptive(minimum: 72), spacing: 10)]
        return LazyVGrid(columns: cols, alignment: .leading, spacing: 10) {
            ForEach(BudgetCategory.allCases) { c in
                Button {
                    category = c
                } label: {
                    HStack(spacing: 6) {
                        Text(categoryEmoji(c))
                        Text(c.displayNameKR)
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(category == c ? Theme.progressFill : Theme.progressBG)
                    .foregroundStyle(category == c ? Color.white : Theme.progressFill)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.black.opacity(0.06))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // 기본 매핑
    private func categoryEmoji(_ c: BudgetCategory) -> String {
        switch c {
        case .income: return "💸"
        case .transportation: return "🚗"
        case .rent: return "🏠"
        case .utilities: return "⚡️"
        case .cafe: return "☕️"
        case .food: return "🍽️"
        case .grocery: return "🛒"
        case .generalMerchandise: return "🛍️"
        case .personalCare: return "🧴"
        case .medical: return "🚑"
        case .entertainment: return "🍿"
        case .generalServices: return "💰"
        case .others: return "🤑"
        }
    }

    // MARK: - Action

    private func addGoal() {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }

        let status = memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ? "\(category.displayNameKR) 목표 추가됨"
        : memo

        let newGoal = Goal(
            title: t,
            type: .reduceSpending,
            isSelected: true,
            isNotificationsOn: true,
            statusText: status,
            category: category
        )

        goalsStore.goals.insert(newGoal, at: 0)
        dismiss()
    }
}
