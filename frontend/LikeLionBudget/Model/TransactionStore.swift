//
//  TransactionStore.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/14/26.
//

import Foundation
import Combine

@MainActor
final class TransactionStore: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    
    init() {}
    // init(seedMonth: Date = Date()) {
    //     let cal = MockData.usCalendar
    //     let start = MockData.startOfMonth(seedMonth)
        
    //     var all: [Transaction] = []
    //     for offset in 0..<30 {
    //         if let date = cal.date(byAdding: .day, value: offset, to: start) {
    //             all.append(contentsOf: MockData.transactions(for: date))
    //         }
    //     }
    //     self.transactions = all
    // }

    // --- THE NEW RAILWAY CONNECTION ---
    func fetchTransactions() async {
        // 1. Point to the live Railway domain
        guard let url = URL(string: "https://ucilikelion-production.up.railway.app/api/transactions") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // 2. Pass the user ID header so backend knows whose data to fetch
        request.setValue("cfaa2f1a-3a6f-4b5a-b839-1d683ae74122", forHTTPHeaderField: "x-user-id")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            let decoder = JSONDecoder()
            // 3. Tell Swift how to read Node.js timestamps
            decoder.dateDecodingStrategy = .iso8601 
            
            let decodedTransactions = try decoder.decode([Transaction].self, from: data)
            
            // 4. Update the UI with the real database records
            self.transactions = decodedTransactions
            
        } catch {
            print("Failed to fetch from Railway: \(error)")
        }
    }
    
    func transactionsForDate(_ date: Date) -> [Transaction] {
        // let cal = MockData.usCalendar
        let cal = Calendar.current
        return transactions
            .filter { cal.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date > $1.date }
    }
    
    func netCents(on date: Date) -> Int {
        transactionsForDate(date).reduce(0) { $0 + $1.amountCents }
    }
    
    // Note for the future: This function will eventually need to be updated
    func addTransaction(date: Date, title: String, amountCents: Int, category: String, merchant: String?) {
        let tx = Transaction(date: date, title: title, amountCents: amountCents, category: category, merchant: merchant)
        transactions.append(tx)
    }
}

