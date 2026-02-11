//
//  FrequentCategoryPicker.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/1/26.
//

import SwiftUI
import Combine


final class RecentCategoryStore: ObservableObject {
    @AppStorage("recentCategories") private var raw: String = ""

    private let maxCount = 5

    func list() -> [BudgetCategory] {
        let parts = raw.split(separator: ",").map { String($0) }
        let cats = parts.compactMap { BudgetCategory(rawValue: $0) }
        var seen = Set<BudgetCategory>()
        return cats.filter { seen.insert($0).inserted }
    }

    func push(_ c: BudgetCategory) {
        var arr = list()
        arr.removeAll { $0 == c }
        arr.insert(c, at: 0)
        if arr.count > maxCount { arr = Array(arr.prefix(maxCount)) }
        raw = arr.map { $0.rawValue }.joined(separator: ",")
    }
}

// MARK: - Frequent Category Picker (Editor)
struct FrequentCategoryPicker: View {
    @Binding var selected: BudgetCategory
    @StateObject private var recent = RecentCategoryStore()
    @State private var showAll = false


    private let fallbackTop5: [BudgetCategory] = [.grocery, .food, .cafe, .transportation, .utilities]

    var body: some View {
        let chips = recent.list().isEmpty ? fallbackTop5 : Array(recent.list().prefix(5))

        VStack(alignment: .leading, spacing: 10) {

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2),
                spacing: 10
            ) {
                ForEach(chips, id: \.self) { c in
                    chip(c)
                }

                Button { showAll = true } label: {
                    HStack(spacing: 8) {
                        Text("📚")
                            .font(.system(size: 16))
                        Text("전체")
                            .font(.custom(Theme.fontLaundry, size: 15))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.beige)
                    .foregroundStyle(Theme.text)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.black.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showAll) {
            CategoryPickerSheet(selected: $selected) { picked in
                recent.push(picked)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.white)
            .presentationCornerRadius(18)
        }
        .onChange(of: selected) { _, newValue in
            recent.push(newValue)
        }
    }

    // MARK: - Chip UI
    private func chip(_ c: BudgetCategory) -> some View {
        Button {
            selected = c
            recent.push(c)
        } label: {
            HStack(spacing: 8) {
                Text(c.emoji)
                    .font(.system(size: 16))

                Text(c.displayNameKR)
                    .font(.custom(Theme.fontLaundry, size: 15))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)

            .background(selected == c ? Theme.progressFill : Theme.beige)
            .foregroundStyle(selected == c ? .white : Theme.text)

            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.black.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Picker Sheet
struct CategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: BudgetCategory
    var onPick: (BudgetCategory) -> Void

    @State private var query: String = ""

    private var filtered: [BudgetCategory] {
        let all = BudgetCategory.allCases
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return all }
        return all.filter { $0.displayNameKR.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { c in
                    Button {
                        selected = c
                        onPick(c)
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Text(c.emoji)

                            Text(c.displayNameKR)
                                .font(.custom(Theme.fontLaundry, size: 16))
                                .foregroundStyle(Theme.text)

                            Spacer()

                            if c == selected {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.progressFill)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.white)
            .navigationTitle("카테고리 선택")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("뒤로") { dismiss() }
                        .foregroundStyle(Theme.text)
                }
            }
        }
    }
}
