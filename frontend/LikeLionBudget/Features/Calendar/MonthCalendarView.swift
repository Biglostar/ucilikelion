//
//  MonthCalendarView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import SwiftUI

// Date는 Identifiable이 아니라 sheet(item:)에 못 씀 → 래퍼
struct SelectedDay: Identifiable {
    let id = UUID()
    let date: Date
}

struct MonthCalendarView: View {
    @Binding var month: Date
    @ObservedObject var store: TransactionStore

    @State private var selectedDay: SelectedDay? = nil

    private let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

    private var grid: [Date?] {
        daysInGrid()
    }

    var body: some View {
        VStack(spacing: 10) {
            header

            HStack {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)

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
            .padding(12)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.08))
            )
        }
        .sheet(item: $selectedDay) { item in
            DayDetailSheet(date: item.date, store: store)
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                month = MockData.usCalendar
                    .date(byAdding: .month, value: -1, to: month) ?? month
            } label: {
                Image(systemName: "chevron.left")
            }

            Spacer()

            Text(monthTitle(month))
                .font(.subheadline.weight(.semibold))

            Spacer()

            Button {
                month = MockData.usCalendar
                    .date(byAdding: .month, value: 1, to: month) ?? month
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .foregroundStyle(Color.green)
        .padding(.horizontal, 6)
    }

    private func monthTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월"
        return f.string(from: date)
    }

    // MARK: - Grid data

    private func daysInGrid() -> [Date?] {
        let cal = MockData.usCalendar
        let start = MockData.startOfMonth(month)

        let weekday = cal.component(.weekday, from: start)
        let leadingBlanks = weekday - 1
        let blanks: [Date?] = Array(repeating: nil, count: leadingBlanks)

        let range = cal.range(of: .day, in: .month, for: start) ?? 1..<31
        let numberOfDays = range.count

        let days: [Date?] = (0..<numberOfDays).compactMap { offset in
            cal.date(byAdding: .day, value: offset, to: start)
        }

        var result = blanks + days
        if result.count < 42 {
            result.append(contentsOf: Array(repeating: nil, count: 42 - result.count))
        }
        if result.count > 42 {
            result = Array(result.prefix(42))
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
