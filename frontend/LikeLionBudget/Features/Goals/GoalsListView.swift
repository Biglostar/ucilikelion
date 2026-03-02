//
//  GoalsListView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//

import SwiftUI

// MARK: - GoalSheetItem

private struct GoalSheetItem: Identifiable {
    let goal: Goal
    var id: UUID { goal.id }
}

struct GoalsListView: View {
    @EnvironmentObject private var onboardingStore: OnboardingStore
    @ObservedObject var goalsStore: GoalsStore

    // MARK: - State

    @State private var showAdd: Bool = false
    @State private var goalToEdit: GoalSheetItem? = nil
    @State private var didOpenAddGoalForOnboarding: Bool = false
    @State private var onboardingFrames: [Int: [CGRect]] = [:]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingStandard) {
                    if !goalsStore.goals.isEmpty {
                        VStack(spacing: Theme.spacingRegular) {
                            ForEach(Array(goalsStore.goals.enumerated()), id: \.element.id) { index, goal in
                                goalRow(
                                    goal: goalsStore.binding(for: goal.id) ?? .constant(goal),
                                    isFirst: index == 0,
                                    onTapToEdit: { goalToEdit = GoalSheetItem(goal: goal) }
                                )
                            }
                        }
                        .llContainer()
                        .onboardingFrame(stepId: 8)
                    }

                    Button {
                        showAdd = true
                    } label: {
                        Text("새로운 목표 추가하기")
                            .font(.custom(Theme.fontLaundry, size: 16))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.buttonVerticalPadding)
                            .background(Theme.progressFill)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
                    }
                    .onboardingFrame(stepId: 10)
                }
                .padding(.horizontal, Theme.screenHorizontal)
                .padding(.top, Theme.screenTop + Theme.screenTopNavExtra)
                .padding(.bottom, Theme.screenBottom)
            }
            .background(Color.white)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("나의 목표")
                        .font(.custom(Theme.fontLaundry, size: Theme.titleSize))
                        .foregroundStyle(Theme.rose)
                }
            }
            .onPreferenceChange(OnboardingFramePreferenceKey.self) { value in
                onboardingFrames = value
                onboardingStore.mergeOnboardingFrames(value)
            }
            .onChange(of: onboardingStore.requestShowAddGoal) { _, requested in
                if requested {
                    showAdd = true
                    didOpenAddGoalForOnboarding = true
                    onboardingStore.requestShowAddGoal = false
                }
            }
            .onChange(of: onboardingStore.currentStep) { _, step in
                if step == 9 && didOpenAddGoalForOnboarding {
                    showAdd = false
                    didOpenAddGoalForOnboarding = false
                }
            }
            .sheet(isPresented: $showAdd, onDismiss: {
                if didOpenAddGoalForOnboarding {
                    onboardingStore.advanceFromAddGoalSheet()
                    didOpenAddGoalForOnboarding = false
                }
            }) {
                ZStack(alignment: .bottom) {
                    AddGoalView(goalsStore: goalsStore)
                        .presentationDetents([.large])
                        .presentationCornerRadius(Theme.sheetCornerRadius)
                    if didOpenAddGoalForOnboarding {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { showAdd = false }
                        Text("아무 곳이나 탭하면 다음으로 넘어갑니다")
                            .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                            .foregroundStyle(Theme.text.opacity(0.5))
                            .padding(.bottom, Theme.screenBottom + 8)
                    }
                }
            }
            .sheet(item: $goalToEdit) { item in
                AddGoalView(goalsStore: goalsStore, editingGoal: item.goal)
                    .presentationDetents([.large])
                    .presentationCornerRadius(Theme.sheetCornerRadius)
            }
        }
    }

    // MARK: - Subviews (goalRow)

    @ViewBuilder
    private func goalRow(goal: Binding<Goal>, isFirst: Bool, onTapToEdit: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Button(action: onTapToEdit) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Theme.progressBG)
                            .frame(width: 36, height: 36)

                        Text(goal.wrappedValue.category.emoji)
                            .font(.system(size: 18))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.wrappedValue.title)
                            .font(.custom(Theme.fontLaundry, size: 16))
                            .foregroundStyle(Theme.text)

                        Text(goal.wrappedValue.category.displayNameKR)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Toggle("", isOn: combinedToggleBinding(for: goal))
                .labelsHidden()
                .tint(Theme.progressFill)
                .onboardingFrame(stepId: 9)
        }
        .padding(12)
        .background(Theme.beige)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .stroke(Color.black.opacity(0.05))
        )
    }

    private func combinedToggleBinding(for goal: Binding<Goal>) -> Binding<Bool> {
        Binding(
            get: { goal.wrappedValue.isSelected || goal.wrappedValue.isNotificationsOn },
            set: { newValue in
                goal.wrappedValue.isSelected = newValue
                goal.wrappedValue.isNotificationsOn = newValue
            }
        )
    }
}
