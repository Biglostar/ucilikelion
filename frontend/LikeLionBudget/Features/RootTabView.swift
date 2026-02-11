//
//  RootTabView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//

import SwiftUI

struct RootTabView: View {
    @StateObject private var transactionStore = TransactionStore()
    @StateObject private var goalsStore = GoalsStore()
    @StateObject private var settingsStore = SettingsStore()

    var body: some View {
        TabView {
            HomeView(store: transactionStore, goalsStore: goalsStore)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }

            ReportView(store: transactionStore)
                .tabItem {
                    Image(systemName: "book.closed")
                    Text("리포트")
                }

            GoalsListView(goalsStore: goalsStore)
                .tabItem {
                    Image(systemName: "checklist")
                    Text("목표")
                }

            SettingsView(settings: settingsStore)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("설정")
                }
        }
        .tint(Theme.rose)
    }
}
