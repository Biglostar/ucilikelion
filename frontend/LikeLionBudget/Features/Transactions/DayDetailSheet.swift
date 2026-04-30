//
//  DayDetailSheet.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import SwiftUI
import UIKit

struct DayDetailSheet: View {
    let date: Date
    @ObservedObject var store: TransactionStore
    @EnvironmentObject var tutorialStore: TutorialStore

    private var cardCorner: CGFloat { Theme.cardCorner }

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
        sheetContent
    }

    private var sheetContent: some View {
        NavigationStack {
            mainList
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
                    ZStack {
                        Circle()

                            .fill(Color(UIColor.tertiarySystemFill))
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Theme.text)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .frame(minWidth: 44, idealWidth: 44, maxWidth: 44, minHeight: 44, idealHeight: 44, maxHeight: 44, alignment: .center)
                    .contentShape(Circle())
                    .clipShape(Circle())
                    .layoutPriority(1)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(item: $activeSheet) { sheetItem in
            sheetContentFor(sheetItem: sheetItem)
        }
        // 튜토리얼 dayDetail 단계 오버레이
        .overlay {
            TutorialSheetOverlayView(store: tutorialStore, activeSteps: [.dayDetail])
        }
        // 튜토리얼: addTransaction 단계 → 추가 에디터 자동 오픈
        .onChange(of: tutorialStore.shouldOpenAddTransaction) { _, should in
            guard should else { return }
            tutorialStore.shouldOpenAddTransaction = false
            activeSheet = .add
        }
        // 튜토리얼: editTransaction 단계 → 수정 에디터 자동 오픈 (첫 번째 거래 내역 사용)
        .onChange(of: tutorialStore.shouldOpenEditTransaction) { _, should in
            guard should else { return }
            tutorialStore.shouldOpenEditTransaction = false
            if let firstTx = transactions.first {
                activeSheet = .edit(firstTx)
            }
        }
    }

    @ViewBuilder
    private func sheetContentFor(sheetItem: ActiveSheet) -> some View {
        switch sheetItem {
        case .add:
            TransactionEditorView(mode: .add(date: date), store: store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.white)
                .presentationCornerRadius(Theme.sheetCornerRadius)
        case .edit(let tx):
            TransactionEditorView(mode: .edit(tx: tx), store: store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.white)
                .presentationCornerRadius(Theme.sheetCornerRadius)
        }
    }

    private var mainList: some View {
        List {
            Section(header: summaryHeader) {
                summaryCard
            }
            Section(header: transactionsHeader) {
                transactionsSectionContent
            }
        }
    }

    private var summaryCard: some View {
        VStack(spacing: Theme.spacingRegular) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.spacingSmall) {
                    Text("지출")
                        .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                        .foregroundStyle(Theme.text)
                    Text("-" + moneyNoPlus(totalExpenseCents))
                        .font(.custom(Theme.fontLaundry, size: Theme.listTitleSize))
                        .foregroundStyle(Theme.minus)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: Theme.spacingSmall) {
                    Text("수입")
                        .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                        .foregroundStyle(Theme.text)
                    Text("+" + moneyNoPlus(totalIncomeCents))
                        .font(.custom(Theme.fontLaundry, size: Theme.listTitleSize))
                        .foregroundStyle(Theme.plus)
                }
            }
            Divider().opacity(0.5)
            HStack {
                Text("합계")
                    .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                    .foregroundStyle(Theme.text)
                Spacer()
                Text(Money.usdSignedString(fromCents: netCents))
                    .font(.custom(Theme.fontLaundry, size: Theme.listTitleSize))
                    .foregroundStyle(netCents >= 0 ? Theme.plus : Theme.minus)
            }
        }
        .padding(Theme.screenHorizontal)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                .stroke(Color.black.opacity(Theme.strokeOpacityLight))
        )
        .listRowInsets(EdgeInsets(top: Theme.listRowInsetVertical, leading: Theme.listRowInsetHorizontal, bottom: Theme.listRowInsetVertical, trailing: Theme.listRowInsetHorizontal))
        .listRowBackground(Color.white)
    }

    @ViewBuilder
    private var transactionsSectionContent: some View {
        if transactions.isEmpty {
            Text("거래 내역이 없어요.")
                .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                .foregroundStyle(Theme.text.opacity(0.6))
                .listRowBackground(Color.white)
        } else {
            ForEach(transactions) { tx in
                transactionRow(tx)
            }
        }
    }

    private func transactionRow(_ tx: Transaction) -> some View {
        let displayName = (tx.merchant?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
            ? (tx.merchant ?? tx.title)
            : tx.title
        let cum = cumulativeById[tx.id] ?? tx.amountCents
        return HStack(alignment: .top, spacing: Theme.spacingRegular) {
            Text(tx.category.emoji)
                .font(.system(size: 22))
                .frame(width: Theme.listIconSize, height: Theme.listIconSize)
                .background(Color.white.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
            VStack(alignment: .leading, spacing: Theme.spacingTight) {
                Text(displayName)
                    .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                    .foregroundStyle(Theme.text)
                Text(timeText(tx.date))
                    .font(.custom(Theme.fontLaundry, size: Theme.captionSmallSize))
                    .foregroundStyle(Theme.text.opacity(0.65))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Theme.spacingTight) {
                Text(Money.usdSignedString(fromCents: tx.amountCents))
                    .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                    .foregroundStyle(tx.amountCents >= 0 ? Theme.plus : Theme.minus)
                Text(Money.usdSignedString(fromCents: cum))
                    .font(.custom(Theme.fontLaundry, size: Theme.captionSmallSize))
                    .foregroundStyle(Theme.text.opacity(0.65))
            }
        }
        .padding(.vertical, Theme.spacingCompact)
        .padding(.horizontal, Theme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                .fill(Theme.beige)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                .stroke(Color.black.opacity(Theme.strokeOpacityLight), lineWidth: Theme.strokeLineWidthThick)
        )
        .contentShape(Rectangle())
        .onTapGesture { activeSheet = .edit(tx) }
        .listRowInsets(EdgeInsets(top: Theme.listRowInsetVerticalCompact, leading: Theme.listRowInsetHorizontal, bottom: Theme.listRowInsetVerticalCompact, trailing: Theme.listRowInsetHorizontal))
        .listRowBackground(Color.white)
    }

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

    private func moneyNoPlus(_ cents: Int) -> String {
        Money.usdSignedString(fromCents: cents).replacingOccurrences(of: "+", with: "")
    }

    private func koDateTitle(_ date: Date) -> String {
        AppFormatters.koDayMonth.string(from: date)
    }

    private func timeText(_ date: Date) -> String {
        AppFormatters.koTime.string(from: date)
    }
}
