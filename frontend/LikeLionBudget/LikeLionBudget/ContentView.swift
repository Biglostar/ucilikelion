//
//  ContentView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var tutorialStore: TutorialStore

    @State private var showLoginSheet = false
    @State private var showTermsSheet = false
    @State private var showPlaidSheet = false
    @State private var plaidStep: PlaidSheetStep = .intro
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .ignoresSafeArea()
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.88).combined(with: .opacity),
                            removal: .scale(scale: 1.06).combined(with: .opacity)
                        )
                    )
            } else {
                RootTabView()
            }
        }
        .animation(.easeInOut(duration: 0.55), value: showSplash)
        .onAppear {
            guard showSplash else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
                // 최초 1회만: 약관 → 로그인 → (미연결 시) Plaid → 튜토리얼
                if !settingsStore.settings.hasAcceptedTerms {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showTermsSheet = true
                    }
                } else {
                    // 재방문: 튜토리얼 미완료 시에만 시작
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        tutorialStore.startIfNeeded()
                    }
                }
            }
        }
        .onChange(of: settingsStore.requestShowLogin) { _, requested in
            if requested {
                showLoginSheet = true
                settingsStore.requestShowLogin = false
            }
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginView(settingsStore: settingsStore)
                .onDisappear {
                    showLoginSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        // 이미 Plaid 연결됨(로그아웃 후 재로그인 등)이면 Plaid 시트를 띄우지 않음
                        guard !settingsStore.settings.plaidConnected else { return }
                        showPlaidSheet = true
                    }
                }
        }
        .sheet(isPresented: $showTermsSheet) {
            TermsAndConsentView(onAgree: {
                settingsStore.setHasAcceptedTerms(true)
                showTermsSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showLoginSheet = true
                }
            })
            .onDisappear {
                showTermsSheet = false
            }
        }
        .onChange(of: showPlaidSheet) { _, show in
            if show { plaidStep = .intro }
        }
        .sheet(isPresented: $showPlaidSheet) {
            Group {
                if plaidStep == .intro {
                    PlaidIntroView(onContinue: {
                        plaidStep = .link
                    })
                } else {
                    PlaidLinkView(settingsStore: settingsStore, onComplete: {
                        showPlaidSheet = false
                        settingsStore.setHasCompletedTermsAndPlaidOnce(true)
                    })
                }
            }
            .onDisappear {
                showPlaidSheet = false
                // Plaid 온보딩 완료 → 튜토리얼 시작
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    tutorialStore.start()
                }
            }
        }
    }
}

private enum PlaidSheetStep {
    case intro
    case link
}

// MARK: - 스플래시

private struct SplashView: View {
    @State private var appeared = false

    var body: some View {
        Theme.beige
            .ignoresSafeArea()
            .overlay {
                Image("SplashIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .scaleEffect(appeared ? 1 : 0.88)
                    .opacity(appeared ? 1 : 0)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5)) { appeared = true }
            }
    }
}
