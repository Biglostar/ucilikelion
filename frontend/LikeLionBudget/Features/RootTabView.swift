//
//  RootTabView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var settingsStore: SettingsStore

    @StateObject private var transactionStore = TransactionStore()
    @StateObject private var goalsStore = GoalsStore()
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(store: transactionStore, goalsStore: goalsStore)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }
                .tag(0)

            GoalsListView(goalsStore: goalsStore)
                .tabItem {
                    Image(systemName: "checklist")
                    Text("목표")
                }
                .tag(1)

            ReportView(store: transactionStore)
                .tabItem {
                    Image(systemName: "book.closed")
                    Text("리포트")
                }
                .tag(2)

            SettingsView(settings: settingsStore)
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("설정")
                }
                .tag(3)
        }
        .tint(Theme.rose)
    }
}
