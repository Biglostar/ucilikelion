//
//  AddTransactionView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/14/26.
//

import SwiftUI

struct AddTransactionView: View {
    let date: Date
    @ObservedObject var store: TransactionStore

    @Environment(\.dismiss) private var dismiss

    @State private var isExpense: Bool = true
    @State private var amountText: String = ""
    @State private var titleText: String = ""
    
    private let categories: [CategoryChip] = [
        .init(title: "식비", icon: "🍚"),
        .init(title: "교통", icon: "🚌"),
        .init(title: "쇼핑", icon: "🛍️"),
        .init(title: "카페", icon: "☕")
    ]
    @State private var selectedCategory: String = "식비"

    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    // Top bar
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("뒤로")
                            }
                        }

                        Spacer()

                        Button {
                            save()
                        } label: {
                            Text("완료")
                                .fontWeight(.semibold)
                        }
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.4)
                    }
                    .padding(.top, 18)
                    .padding(.bottom, 6)

                    // Date
                    Text(dateTitle(date))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color.green)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("새로운 거래 내역 추가")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // Expense / Income segmented
                    HStack(spacing: 0) {
                        segButton(title: "지출", isOn: isExpense) {
                            isExpense = true
                        }
                        segButton(title: "수입", isOn: !isExpense) {
                            isExpense = false
                        }
                    }
                    .background(Color.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Amount
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("금액")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("USD")
                                .foregroundStyle(.secondary)
                        }
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.title3.weight(.semibold))
                            .padding(.vertical, 10)
                        Divider()
                    }

                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("제목")
                            .foregroundStyle(.secondary)
                        TextField("e.g., Coffee", text: $titleText)
                            .padding(.vertical, 10)
                        Divider()
                    }

                    // Category chips
                    Text("카테고리")
                        .font(.headline)
                        .padding(.top, 8)

                    HStack(spacing: 10) {
                        ForEach(categories) { c in
                            chip(title: c.title, icon: c.icon, selected: selectedCategory == c.title) {
                                selectedCategory = c.title
                            }
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }

        private func segButton(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isOn ? Color.white : Color.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isOn ? Color.green : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }

        private func chip(title: String, icon: String, selected: Bool, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                HStack(spacing: 6) {
                    Text(icon)
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .foregroundStyle(selected ? Color.white : Color.green)
                .background(selected ? Color.green : Color.green.opacity(0.12))
                .clipShape(Capsule())
            }
        }

        private var canSave: Bool {
            !titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            parseCents(from: amountText) != nil
        }

        private func save() {
            guard let cents = parseCents(from: amountText) else { return }
            let signedCents = isExpense ? -abs(cents) : abs(cents)

            store.addTransaction(
                date: date,
                title: titleText,
                amountCents: signedCents,
                category: selectedCategory,
                merchant: nil
            )
            dismiss()
        }

        private func parseCents(from text: String) -> Int? {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            guard let dec = Decimal(string: trimmed) else { return nil }
            let centsDec = dec * 100
            return NSDecimalNumber(decimal: centsDec).intValue
        }

        private func dateTitle(_ date: Date) -> String {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ko_KR")
            f.dateFormat = "M월 d일"
            return f.string(from: date)
        }
    }

    struct CategoryChip: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
    }
