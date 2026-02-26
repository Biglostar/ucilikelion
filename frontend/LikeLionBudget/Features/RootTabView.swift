//
//  RootTabView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var onboardingStore: OnboardingStore
    @StateObject private var transactionStore = TransactionStore()
    @StateObject private var goalsStore = GoalsStore()
    @StateObject private var settingsStore = SettingsStore()
    @State private var selectedTab: Int = 0

    private var tabSelection: Binding<Int> {
        Binding(
            get: { onboardingStore.isTutorialActive ? onboardingStore.tutorialTabIndex : selectedTab },
            set: { new in
                if onboardingStore.isTutorialActive {
                    onboardingStore.tutorialTabIndex = new
                } else {
                    selectedTab = new
                }
            }
        )
    }

    var body: some View {
        TabView(selection: tabSelection) {
            HomeView(store: transactionStore, goalsStore: goalsStore)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }
                .tag(0)

            ReportView(store: transactionStore)
                .tabItem {
                    Image(systemName: "book.closed")
                    Text("리포트")
                }
                .tag(1)

            GoalsListView(goalsStore: goalsStore)
                .tabItem {
                    Image(systemName: "checklist")
                    Text("목표")
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
        .onAppear {
            transactionStore.bindOnboarding(onboardingStore)
            goalsStore.bindOnboarding(onboardingStore)
        }
        .overlay {
            let step = onboardingStore.currentStep
            if onboardingStore.isTutorialActive && [6, 7].contains(step) {
                Color.black.opacity(0.80)
                    .ignoresSafeArea(.all)
            } else if onboardingStore.isTutorialActive && (1...5).contains(step) || (8...12).contains(step) {
                GeometryReader { g in
                    OnboardingOverlayView(
                        store: onboardingStore,
                        frames: onboardingStore.collectedOnboardingFrames,
                        screenSize: g.size
                    )
                }
                .ignoresSafeArea(.all)
            }
        }
    }
}
