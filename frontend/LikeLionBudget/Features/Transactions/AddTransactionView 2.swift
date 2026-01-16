//
//  AddTransactionView 2.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/15/26.
//


import SwiftUI

struct AddTransactionView: View {
    let date: Date
    @ObservedObject var store: TransactionStore

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var amountText: String = ""
    @State private var category: String = "Misc"
    @State private var isExpense: Bool = true

    @FocusState private var focusedField: Field?

    private enum Field {
        case title, amount, category
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("e.g., Coffee", text: $title)
                        .focused($focusedField, equals: .title)
                }

                Section("Amount (USD)") {
                    TextField("e.g., 6.50", text: $amountText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)

                    Toggle("Expense?", isOn: $isExpense)
                }

                Section("Category") {
                    TextField("e.g., Coffee", text: $category)
                        .focused($focusedField, equals: .category)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationTitle("Add Transaction")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
        .onAppear {
            focusedField = .title
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        parseCents(from: amountText) != nil
    }

    private func save() {
        guard let cents = parseCents(from: amountText) else { return }
        let signedCents = isExpense ? -abs(cents) : abs(cents)
        store.addTransaction(date: date, title: title, amountCents: signedCents, category: category, merchant: nil)
        dismiss()
    }

    private func parseCents(from text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let dec = Decimal(string: trimmed) else { return nil }
        let centsDec = dec * 100
        return NSDecimalNumber(decimal: centsDec).intValue
    }
}