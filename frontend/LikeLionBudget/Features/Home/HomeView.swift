//
//  HomeView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import SwiftUI

struct HomeView: View {
    @State private var selectedMonth: Date = Date()
    @StateObject private var store = TransactionStore()
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Home")
                .font(.title.bold())
            
            MonthCalendarView(month: $selectedMonth, store: store)
        }
        .padding()
    }
}
