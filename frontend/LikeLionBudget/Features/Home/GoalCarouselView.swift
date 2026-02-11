//
//  GoalCarouselView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/31/26.
//

import SwiftUI

struct GoalCarouselView: View {
    let goals: [Goal]
    @Binding var selectedGoalID: UUID?
    
    private let swipeHeight: CGFloat = 26
    private let swipeThreshold: CGFloat = 30

    var body: some View {
        VStack(spacing: 8) {

            // MARK: Header (Left/Right + Title)
            HStack {
                Button { step(-1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                }
                .buttonStyle(.plain)
                .disabled(goals.count <= 1)
                .opacity(goals.count <= 1 ? 0.3 : 1)

                Spacer()

                Text(currentTitle)
                    .font(.custom(Theme.fontLaundry, size: 20)) // 제목 크기 조절
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)

                Spacer()

                Button { step(1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                }
                .buttonStyle(.plain)
                .disabled(goals.count <= 1)
                .opacity(goals.count <= 1 ? 0.3 : 1)
            }

            // MARK: Swipe hit area
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .frame(height: swipeHeight)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onEnded { value in
                            guard goals.count > 1 else { return }
                            let dx = value.translation.width
                            if dx <= -swipeThreshold { step(1) }
                            else if dx >= swipeThreshold { step(-1) }
                        }
                )
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

    // MARK: - Helpers
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
