//
//  TransactionEditorView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/31/26.
//

import SwiftUI

struct TransactionEditorView: View {

    enum Mode {
        case add(date: Date)
        case edit(tx: Transaction)
    }

    let mode: Mode
    @ObservedObject var store: TransactionStore
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var title: String
    @State private var amountText: String
    @State private var category: BudgetCategory
    @State private var isExpense: Bool
    @State private var isFixed: Bool

    private let editingID: UUID?
    private let editingMerchant: String?

    init(mode: Mode, store: TransactionStore) {
        self.mode = mode
        self.store = store

        switch mode {
        case .add(let d):
            _date = State(initialValue: d)
            _title = State(initialValue: "")
            _amountText = State(initialValue: "")
            _category = State(initialValue: .others)
            _isExpense = State(initialValue: true)
            _isFixed = State(initialValue: false)
            editingID = nil
            editingMerchant = nil

        case .edit(let tx):
            _date = State(initialValue: tx.date)
            _title = State(initialValue: tx.title)
            _category = State(initialValue: tx.category)

            let absCents = abs(tx.amountCents)
            let dollars = Double(absCents) / 100.0
            _amountText = State(initialValue: String(format: "%.2f", dollars))

            _isExpense = State(initialValue: tx.amountCents < 0)
            _isFixed = State(initialValue: tx.isFixed)

            editingID = tx.id
            editingMerchant = tx.merchant
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    VStack(alignment: .leading, spacing: 12) {

                        headerBlock()

                        ExpenseIncomeSegment(isExpense: $isExpense)

                        inputBlock()

                        Text("카테고리")
                            .font(.custom(Theme.fontLaundry, size: 16))
                            .foregroundStyle(Theme.text)

                        FrequentCategoryPicker(selected: $category)

                        fixedBlock()

                        dateTimeBlock()

                        buttonsBlock()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
            .background(Color.white)

            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("뒤로") { dismiss() }
                        .foregroundStyle(Theme.text)
                }

                ToolbarItem(placement: .principal) {
                    Text(koDateTitle(date))
                        .font(.custom(Theme.fontLaundry, size: 22))
                        .foregroundStyle(Theme.rose)
                }
            }
        }
    }

    // MARK: - Blocks

    @ViewBuilder
    private func headerBlock() -> some View {
        Text(isEdit ? "거래 내역 수정" : "새로운 거래 내역")
            .font(.custom(Theme.fontLaundry, size: 22))
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 6)
    }
    
    @ViewBuilder
    private func inputBlock() -> some View {
        VStack(spacing: 12) {

            VStack(alignment: .leading, spacing: 8) {
                Text("제목")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.text)

                TextField("예: 커피", text: $title)
                    .textInputAutocapitalization(.words)

                Divider().opacity(0.35)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("금액")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.text.opacity(0.65))

                HStack {
                    TextField("예: 6.50", text: $amountText)
                        .keyboardType(.decimalPad)
                    Spacer()
                    Text("USD")
                        .foregroundStyle(Theme.text)
                }

                Divider().opacity(0.35)
            }
        }
        .cardStyle(bg: Color.clear, corner: 8, strokeOpacity: 0.06, padding: 14)
    }

    @ViewBuilder
    private func fixedBlock() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $isFixed) {
                Text("고정지출")
                    .font(.custom(Theme.fontLaundry, size: 16))
                    .foregroundStyle(Theme.text)
            }
            .tint(Theme.progressFill)

                Text("고정지출로 체크하면 리포트의 고정지출 계산에 포함될 예정")
                    .font(.caption)
                    .foregroundStyle(Theme.text.opacity(0.65))
        }
        .cardStyle(bg: Theme.beige, corner: 8, strokeOpacity: 0.06, padding: 14)
    }

    @ViewBuilder
    private func dateTimeBlock() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("날짜 · 시간")
                .font(.custom(Theme.fontLaundry, size: 16))
                .foregroundStyle(Theme.text)

            DatePicker(
                "",
                selection: $date,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
        }
        .cardStyle(bg: Theme.beige, corner: 8, strokeOpacity: 0.06, padding: 14)
    }

    @ViewBuilder
    private func buttonsBlock() -> some View {
        VStack(spacing: 10) {
            Button { save() } label: {
                Text(isEdit ? "저장" : "추가하기")
                    .font(.custom(Theme.fontLaundry, size: 16))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.progressFill)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .disabled(!canSave)
            .opacity(canSave ? 1.0 : 0.5)

            if isEdit {
                Button(role: .destructive) {
                    if let id = editingID { store.deleteTransaction(id: id) }
                    dismiss()
                } label: {
                    Text("삭제")
                        .font(.custom(Theme.fontLaundry, size: 16))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.overBG)
                        .foregroundStyle(Theme.overFill)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .padding(.top, 2)
    }

    // MARK: - Computed

    private var isEdit: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && parseCents(from: amountText) != nil
    }

    // MARK: - Actions

    private func save() {
        guard let cents = parseCents(from: amountText) else { return }
        let signedCents = isExpense ? -abs(cents) : abs(cents)

        if isEdit, let id = editingID {
            let updated = Transaction(
                id: id,
                date: date,
                title: title,
                amountCents: signedCents,
                category: category,
                merchant: editingMerchant,
                isFixed: isFixed
            )
            store.updateTransaction(updated)
        } else {
            store.addTransaction(
                date: date,
                title: title,
                amountCents: signedCents,
                category: category,
                merchant: nil,
                isFixed: isFixed
            )
        }
        dismiss()
    }

    private func parseCents(from text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let dec = Decimal(string: trimmed) else { return nil }
        let centsDec = dec * 100
        return NSDecimalNumber(decimal: centsDec).intValue
    }

    private func koDateTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f.string(from: date)
    }
}

// MARK: - UI Parts
private struct ExpenseIncomeSegment: View {
    @Binding var isExpense: Bool

    var body: some View {
        ZStack {
            Capsule()
                .fill(Theme.beige)

            HStack(spacing: 0) {
                segmentButton(
                    title: "지출",
                    selected: isExpense
                ) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        isExpense = true
                    }
                }

                segmentButton(
                    title: "수입",
                    selected: !isExpense
                ) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        isExpense = false
                    }
                }
            }
            .padding(4)
        }
        .frame(height: 50)
        .overlay(
            Capsule()
                .stroke(Color.black.opacity(0.06))
        )
    }

    // MARK: - Segment Button
    private func segmentButton(
        title: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom(Theme.fontLaundry, size: 16))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Capsule()
                        .fill(selected ? Theme.progressFill : Color.clear)
                )
                .foregroundStyle(selected ? .white : Theme.text)
        }
        .buttonStyle(.plain)
    }
}
