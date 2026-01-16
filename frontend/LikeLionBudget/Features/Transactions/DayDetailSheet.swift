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

    @State private var showAdd: Bool = false

    private var transactions: [Transaction] {
        store.transactionsForDate(date)
    }
    
    private var totalIncomeCents: Int {
        transactions
            .filter { $0.amountCents > 0 }
            .reduce(0) { $0 + $1.amountCents }
    }
    
    private var totalExpenseCents: Int {
        transactions
            .filter { $0.amountCents < 0 }
            .reduce(0) { $0 + abs($1.amountCents) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("요약") {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("지출")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("-" + Money.usdString(fromCents: totalIncomeCents))
                                .font(.headline)
                                .foregroundStyle(.red)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("수입")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("+" + Money.usdString(fromCents: totalIncomeCents))
                                .font(.headline)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 6)
                }
                Section("거래 내역") {
                    if transactions.isEmpty {
                        Text("거래 내역이 없어요.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(transactions) { tx in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tx.title)
                                        .font(.headline)
                                    Text(tx.category)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(Money.usdSignedString(fromCents: tx.amountCents))
                                    .font(.headline)
                                    .foregroundStyle(tx.amountCents >= 0 ? Color.blue : Color.red)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .navigationTitle(usDateTitle(date))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Label("추가", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddTransactionView(date: date, store: store)
                    .presentationDetents([.fraction(0.90), .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func usDateTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f.string(from: date)
    }
}
