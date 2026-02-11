//
//  MonthCalendarView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import SwiftUI

struct SelectedDay: Identifiable {
    let id = UUID()
    let date: Date
}

struct MonthCalendarView: View {
    @Binding var month: Date
    @ObservedObject var store: TransactionStore

    @State private var selectedDay: SelectedDay? = nil

    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]
    private var grid: [Date?] { daysInGrid() }

    // MARK: Body
    var body: some View {
        VStack(spacing: 10) {

            VStack(spacing: 10) {
                header

                HStack {
                    ForEach(weekdaySymbols, id: \.self) { day in
                        Text(day)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.weekdaySimbol)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 4)

                // MARK: - Grid
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 7),
                    spacing: 10
                ) {
                    ForEach(Array(grid.enumerated()), id: \.offset) { _, dateOpt in
                        if let date = dateOpt {
                            DayCellView(
                                date: date,
                                netCents: netCents(for: date),
                                isSelected: isSelected(date)
                            )
                            .onTapGesture {
                                selectedDay = SelectedDay(date: date)
                            }
                        } else {
                            Color.clear.frame(height: 42)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.black.opacity(0.08))
            )
        }

        // MARK: - Day detail sheet
        .sheet(item: $selectedDay) { item in
            DayDetailSheetContainer(date: item.date, store: store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.white)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 10) {

            Button { stepMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(Theme.rose)
            }

            Spacer()

            Text(monthTitle(month))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: "#000000"))

            Spacer()

            Button { stepMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(Theme.rose)
            }
        }
    }
    // MARK: - Title helper
    private func monthTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    // MARK: - Month step
    private func stepMonth(_ delta: Int) {
        let cal = MockData.usCalendar
        month = cal.date(byAdding: .month, value: delta, to: month) ?? month
    }

    // MARK: - Grid data
    private func daysInGrid() -> [Date?] {
        let cal = MockData.usCalendar
        let start = MockData.startOfMonth(month)

        let weekday = cal.component(.weekday, from: start)
        let leading = weekday - 1
        var result: [Date?] = Array(repeating: nil, count: leading)

        let range = cal.range(of: .day, in: .month, for: start) ?? 1..<31
        for offset in 0..<range.count {
            result.append(cal.date(byAdding: .day, value: offset, to: start))
        }

        let remainder = result.count % 7
        if remainder != 0 {
            result.append(contentsOf: Array(repeating: nil, count: 7 - remainder))
        }
        return result
    }

    // MARK: - Helpers
    private func netCents(for date: Date) -> Int {
        store.netCents(on: date)
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selected = selectedDay?.date else { return false }
        return MockData.usCalendar.isDate(selected, inSameDayAs: date)
    }
}

// MARK: - DayDetailSheetContainer
private struct DayDetailSheetContainer: View {
    let date: Date
    @ObservedObject var store: TransactionStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DayDetailSheet(date: date, store: store)
                .background(Color.white)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("뒤로") { dismiss() }
                            .foregroundStyle(Theme.text)
                    }
                }
        }
    }
}
