//
//  AddGoalView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//

import SwiftUI

struct AddGoalView: View {
    @ObservedObject var goalsStore: GoalsStore
    var editingGoal: Goal? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var memo: String = ""
    @State private var category: BudgetCategory = .others

    private var isEditMode: Bool { editingGoal != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingStandard) {

                    VStack(spacing: Theme.spacingRegular) {

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
                        .cardStyle(bg: Theme.beige, corner: Theme.cardCorner, strokeOpacity: 0.06, padding: Theme.cardPadding)

                        VStack(spacing: Theme.spacingRegular) {
                            Text("목표 카테고리")
                                .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                                .foregroundStyle(Theme.text)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            categoryChips

                            Text("AI가 지난 소비 패턴 바탕으로 목표치를 설정해 줘요")
                                .font(.caption)
                                .foregroundStyle(Theme.text.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 4)
                        }
                        .padding(.vertical, 4)

                        VStack(spacing: 10) {
                            Button { saveGoal() } label: {
                                Text(isEditMode ? "저장" : "추가하기")
                                    .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Theme.buttonVerticalPadding)
                                    .background(Theme.progressFill)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
                            }
                            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)

                            if isEditMode {
                                Button(role: .destructive) {
                                    deleteGoal()
                                } label: {
                                    Text("삭제")
                                        .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, Theme.buttonVerticalPadding)
                                        .background(Theme.overBG)
                                        .foregroundStyle(Theme.minus)
                                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
                                }
                            }
                        }
                        .padding(.top, 2)

                    }
                    .background(Color.clear)
                }
                .padding(.horizontal, Theme.screenHorizontal)
                .padding(.top, Theme.screenTop)
                .padding(.bottom, Theme.screenBottom)
            }
            .background(Color.white)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(isEditMode ? "목표 수정" : "새로운 목표")
                        .font(.custom(Theme.fontLaundry, size: Theme.titleSize))
                        .foregroundStyle(Theme.rose)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("뒤로") { dismiss() }
                        .foregroundStyle(Theme.text)
                }
            }
            .onAppear {
                if let g = editingGoal {
                    title = g.title
                    memo = g.statusText
                    category = g.category
                }
            }
        }
    }

    // MARK: - Chips

    private var categoryChips: some View {
        let all = Array(BudgetCategory.allCases)
        return VStack(alignment: .center, spacing: 14) {
            FlowLayout(horizontalSpacing: 10, verticalSpacing: 10) {
                categoryButton(all[0])
                categoryButton(all[1])
                categoryButton(all[2])
                categoryButton(all[3])
                categoryButton(all[4])
                categoryButton(all[5])
                categoryButton(all[6])
            }
            FlowLayout(horizontalSpacing: 10, verticalSpacing: 10) {
                categoryButton(all[7])
                categoryButton(all[8])
                categoryButton(all[9])
                categoryButton(all[10])
                categoryButton(all[11])
                categoryButton(all[12])
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func categoryButton(_ c: BudgetCategory) -> some View {
        Button {
            category = c
        } label: {
            HStack(spacing: 6) {
                Text(categoryEmoji(c))
                    .font(.system(size: 15))
                Text(c.displayNameKR)
                    .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                    .fontWeight(.semibold)
            }
            .padding(.vertical, Theme.spacingSmall + 4)
            .padding(.horizontal, Theme.cardPadding)
            .background(category == c ? Theme.progressFill : Theme.progressBG)
            .foregroundStyle(category == c ? Color.white : Theme.progressFill)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(category == c ? Color.clear : Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: true)
    }

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

    private func saveGoal() {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }

        let status = memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "\(category.displayNameKR) 목표 추가됨"
            : memo

        if let existing = editingGoal {
            let updated = Goal(
                id: existing.id,
                title: t,
                type: existing.type,
                isSelected: existing.isSelected,
                isNotificationsOn: existing.isNotificationsOn,
                statusText: status,
                category: category
            )
            goalsStore.updateGoal(updated)
        } else {
            let newGoal = Goal(
                title: t,
                type: .reduceSpending,
                isSelected: true,
                isNotificationsOn: true,
                statusText: status,
                category: category
            )
            goalsStore.insertGoal(newGoal)
        }
        dismiss()
    }

    private func deleteGoal() {
        guard let g = editingGoal else { return }
        goalsStore.deleteGoal(id: g.id)
        dismiss()
    }
}
