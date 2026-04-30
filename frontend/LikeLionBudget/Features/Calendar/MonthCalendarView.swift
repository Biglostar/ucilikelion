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
    @Binding var selectedDay: SelectedDay?

    private let weekdaySymbols = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    private var grid: [Date] { daysInGrid() }

    // MARK: Body
    var body: some View {
        VStack(spacing: Theme.spacingCompact) {

            VStack(spacing: Theme.spacingCompact) {
                header

                HStack {
                    ForEach(weekdaySymbols, id: \.self) { day in
                        Text(day)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(Theme.weekdaySimbol)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 4)

                // MARK: - Grid (현재 달 + 이전/다음 달 날짜)
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 7),
                    spacing: Theme.spacingCompact
                ) {
                    ForEach(Array(grid.enumerated()), id: \.offset) { _, date in
                        DayCellView(
                            date: date,
                            netCents: netCents(for: date),
                            hasTransactions: hasTransactions(for: date),
                            isSelected: isSelected(date),
                            isCurrentMonth: isInDisplayedMonth(date)
                        )
                        .onTapGesture {
                            selectedDay = SelectedDay(date: date)
                        }
                    }
                }
            }
            .padding(.vertical, Theme.spacingRegular)
            .padding(.horizontal, Theme.spacingRegular)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .stroke(Color.black.opacity(Theme.strokeOpacityMedium))
            )
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: Theme.spacingCompact) {

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
        return AppFormatters.enMonthYear.string(from: date)
    }

    // MARK: - Month step
    private func stepMonth(_ delta: Int) {
        let cal = MockData.usCalendar
        month = cal.date(byAdding: .month, value: delta, to: month) ?? month
    }

    // MARK: - Grid data
    private func daysInGrid() -> [Date] {
        let cal = MockData.usCalendar
        let start = MockData.startOfMonth(month)
        let range = cal.range(of: .day, in: .month, for: start) ?? 1..<31
        let monthDays = range.count
        let weekday = cal.component(.weekday, from: start)
        let leading = weekday - 1
        let remainder = (leading + monthDays) % 7
        let trailing = remainder == 0 ? 0 : (7 - remainder)

        var result: [Date] = []

        if leading > 0, let prevMonth = cal.date(byAdding: .month, value: -1, to: start) {
            let prevRange = cal.range(of: .day, in: .month, for: prevMonth) ?? 1..<31
            let prevDays = prevRange.count
            for i in 0..<leading {
                result.append(cal.date(byAdding: .day, value: prevDays - leading + i, to: prevMonth)!)
            }
        }
        for offset in 0..<monthDays {
            result.append(cal.date(byAdding: .day, value: offset, to: start)!)
        }
        if trailing > 0, let nextMonth = cal.date(byAdding: .month, value: 1, to: start) {
            for offset in 0..<trailing {
                result.append(cal.date(byAdding: .day, value: offset, to: nextMonth)!)
            }
        }
        return result
    }

    private func isInDisplayedMonth(_ date: Date) -> Bool {
        MockData.usCalendar.isDate(date, equalTo: month, toGranularity: .month)
    }

    // MARK: - Helpers
    private func netCents(for date: Date) -> Int {
        store.netCents(on: date)
    }

    private func hasTransactions(for date: Date) -> Bool {
        !store.transactionsForDate(date).isEmpty
    }

    private func isSelected(_ date: Date) -> Bool {
        guard let selected = selectedDay?.date else { return false }
        return MockData.usCalendar.isDate(selected, inSameDayAs: date)
    }
}

// MARK: - DayDetailSheetContainer
struct DayDetailSheetContainer: View {
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
