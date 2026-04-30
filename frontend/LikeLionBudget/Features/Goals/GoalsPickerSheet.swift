//
//  GoalsPickerSheet.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//

import SwiftUI

struct GoalsPickerSheet: View {
    @ObservedObject var goalsStore: GoalsStore
    @Binding var selectedGoalID: UUID?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: Theme.spacingCompact) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 44, height: 5)
                .padding(.top, 8)
            
            Text("목표 선택")
                .font(.headline)
                .padding(.bottom, 4)
            
            List {
                ForEach(goalsStore.goals) { goal in
                    Button {
                        selectedGoalID = goal.id
                        dismiss()
                    } label: {
                        HStack {
                            Text(goal.title)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedGoalID == goal.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}
