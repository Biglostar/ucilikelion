//
//  GoalsListView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//

import SwiftUI

struct GoalsListView: View {
    @ObservedObject var goalsStore: GoalsStore
    @State private var showAdd: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {

                    VStack(spacing: 10) {
                        ForEach($goalsStore.goals) { $goal in
                            goalRow(goal: $goal)
                        }
                    }
                    .llContainer()

                    Button {
                        showAdd = true
                    } label: {
                        Text("새로운 목표 추가하기")
                            .font(.custom(Theme.fontLaundry, size: 16))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.progressFill)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
            .llScreen()
            .llNavTitle("나의 목표")
            .sheet(isPresented: $showAdd) {
                AddGoalView(goalsStore: goalsStore)
                    .presentationDetents([.large])
            }
        }
    }

    @ViewBuilder
    private func goalRow(goal: Binding<Goal>) -> some View {
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

            Spacer()

            // 목표 통합 토글
            Toggle("", isOn: combinedToggleBinding(for: goal))
                .labelsHidden()
                .tint(Theme.progressFill)
        }
        .padding(12)
        .background(Theme.beige)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
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
