//
//  DayDetailSheet.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import SwiftUI

struct DayDetailSheet: View {
    let date: Date
    @ObservedObject var store: TransactionStore

    private let cardCorner: CGFloat = 8

    private enum ActiveSheet: Identifiable {
        case add
        case edit(Transaction)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let tx): return "edit-\(tx.id)"
            }
        }
    }

    @State private var activeSheet: ActiveSheet? = nil

    private var transactions: [Transaction] {
        store.transactionsForDate(date)
    }

    private var cumulativeById: [UUID: Int] {
        var running = 0
        var dict: [UUID: Int] = [:]
        for tx in transactions.reversed() {
            running += tx.amountCents
            dict[tx.id] = running
        }
        return dict
    }

    private var totalIncomeCents: Int {
        transactions.filter { $0.amountCents > 0 }.reduce(0) { $0 + $1.amountCents }
    }

    private var totalExpenseCents: Int {
        transactions.filter { $0.amountCents < 0 }.reduce(0) { $0 + abs($1.amountCents) }
    }

    private var netCents: Int {
        transactions.reduce(0) { $0 + $1.amountCents }
    }

    var body: some View {
        NavigationStack {
            List {

                // MARK: - 요약 (요약 → 지출/수입 → 합계)
                Section(header: summaryHeader) {
                    VStack(spacing: 12) {

                        // MARK: 지출 / 수입
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("지출")
                                    .font(.custom(Theme.fontLaundry, size: 14))
                                    .foregroundStyle(Theme.text)

                                Text("-" + moneyNoPlus(totalExpenseCents))
                                    .font(.custom(Theme.fontLaundry, size: 18))
                                    .foregroundStyle(Theme.minus)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 6) {
                                Text("수입")
                                    .font(.custom(Theme.fontLaundry, size: 14))
                                    .foregroundStyle(Theme.text)

                                Text("+" + moneyNoPlus(totalIncomeCents))
                                    .font(.custom(Theme.fontLaundry, size: 18))
                                    .foregroundStyle(Theme.plus)
                            }
                        }

                        Divider().opacity(0.5)

                        // MARK: 합계
                        HStack {
                            Text("합계")
                                .font(.custom(Theme.fontLaundry, size: 13))
                                .foregroundStyle(Theme.text)

                            Spacer()

                            Text(Money.usdSignedString(fromCents: netCents))
                                .font(.custom(Theme.fontLaundry, size: 18))
                                .foregroundStyle(netCents >= 0 ? Theme.plus : Theme.minus)
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: cardCorner, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                            .stroke(Color.black.opacity(0.06))
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.white)
                }

                // MARK: - 거래 내역
                Section(header: transactionsHeader) {
                    if transactions.isEmpty {
                        Text("거래 내역이 없어요.")
                            .font(.custom(Theme.fontLaundry, size: 14))
                            .foregroundStyle(Theme.text.opacity(0.6))
                            .listRowBackground(Color.white)
                    } else {
                        ForEach(transactions) { tx in
                            let displayName = (tx.merchant?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
                            ? (tx.merchant ?? tx.title)
                            : tx.title

                            let cum = cumulativeById[tx.id] ?? tx.amountCents

                            HStack(alignment: .top, spacing: 12) {

                                Text(tx.category.emoji)
                                    .font(.system(size: 22))
                                    .frame(width: 34, height: 34)
                                    .background(Color.white.opacity(0.7))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(displayName)
                                        .font(.custom(Theme.fontLaundry, size: 16))
                                        .foregroundStyle(Theme.text)

                                    Text(timeText(tx.date))
                                        .font(.custom(Theme.fontLaundry, size: 12))
                                        .foregroundStyle(Theme.text.opacity(0.65))
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(Money.usdSignedString(fromCents: tx.amountCents))
                                        .font(.custom(Theme.fontLaundry, size: 16))
                                        .foregroundStyle(tx.amountCents >= 0 ? Theme.plus : Theme.minus)

                                    Text(Money.usdSignedString(fromCents: cum))
                                        .font(.custom(Theme.fontLaundry, size: 12))
                                        .foregroundStyle(Theme.text.opacity(0.65))
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(
                                RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                                    .fill(Theme.beige)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                                    .stroke(Color.black.opacity(0.06), lineWidth: 1.2)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { activeSheet = .edit(tx) }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.white)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.white)

            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .topBarLeading) {
                    EmptyView()
                }

                ToolbarItem(placement: .principal) {
                    Text(koDateTitle(date))
                        .font(.custom(Theme.fontLaundry, size: 22))
                        .foregroundStyle(Theme.rose)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button { activeSheet = .add } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.text)
                    }
                }
            }

            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .add:
                    TransactionEditorView(mode: .add(date: date), store: store)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                        .presentationBackground(.white)
                        .presentationCornerRadius(0)

                case .edit(let tx):
                    TransactionEditorView(mode: .edit(tx: tx), store: store)
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                        .presentationBackground(.white)
                        .presentationCornerRadius(0)
                }
            }
        }
    }

    // MARK: - Headers

    private var summaryHeader: some View {
        Text("요약")
            .font(.custom(Theme.fontLaundry, size: 16))
            .foregroundStyle(Theme.text)
    }

    private var transactionsHeader: some View {
        Text("거래 내역")
            .font(.custom(Theme.fontLaundry, size: 16))
            .foregroundStyle(Theme.text)
    }

    // MARK: - Helpers

    private func moneyNoPlus(_ cents: Int) -> String {
        Money.usdSignedString(fromCents: cents).replacingOccurrences(of: "+", with: "")
    }

    private func koDateTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f.string(from: date)
    }

    private func timeText(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
