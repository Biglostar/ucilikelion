//
//  RootTabView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var tutorialStore: TutorialStore

    @StateObject private var transactionStore = TransactionStore()
    @StateObject private var goalsStore = GoalsStore()
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack {
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

            // 튜토리얼 오버레이 — 최상위에서 전체 화면 덮기
            if tutorialStore.isActive {
                TutorialOverlayView(store: tutorialStore)
                    .ignoresSafeArea()
            }
        }
        .onChange(of: tutorialStore.currentStep) { _, step in
            guard tutorialStore.isActive else { return }
            withAnimation { selectedTab = step.requiredTab }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                tutorialStore.refreshFrames()
            }
        }
        .onChange(of: tutorialStore.isActive) { _, active in
            goalsStore.isTutorialMode = active
        }
    }
}
