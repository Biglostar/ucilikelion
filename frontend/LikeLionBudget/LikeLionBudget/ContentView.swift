//
//  ContentView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var onboardingStore: OnboardingStore
    @EnvironmentObject private var settingsStore: SettingsStore

    // MARK: - State

    @State private var showLoginSheet = false
    @State private var showTermsSheet = false
    @State private var showPlaidSheet = false
    @State private var plaidStep: PlaidSheetStep = .intro
    @State private var showSplash = true
    @State private var showPostTutorialCover = false

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
                mainContent
            }
        }
        .animation(.easeInOut(duration: 0.55), value: showSplash)
        .onChange(of: onboardingStore.showPostTutorialScreen) { _, new in
            showPostTutorialCover = new
        }
        .fullScreenCover(isPresented: $showPostTutorialCover) {
            PostTutorialOverlay(onConnect: {
                showPostTutorialCover = false
                onboardingStore.showPostTutorialScreen = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    onboardingStore.showLoginAfterTutorial = true
                }
            })
        }
        .onAppear {
            guard showSplash else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
                if !onboardingStore.hasSeenWelcome {
                    onboardingStore.startTutorial()
                }
            }
        }
        .onChange(of: onboardingStore.showLoginAfterTutorial) { _, shouldShow in
            if shouldShow { showLoginSheet = true }
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginView(settingsStore: settingsStore)
                .onDisappear {
                    showLoginSheet = false
                    onboardingStore.showLoginAfterTutorial = false
                    if !settingsStore.settings.hasCompletedTermsAndPlaidOnce {
                        showTermsSheet = true
                    }
                }
        }
        .sheet(isPresented: $showTermsSheet) {
            TermsAndConsentView(onAgree: {
                showTermsSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showPlaidSheet = true
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
                        onboardingStore.markPostOnboardingDone()
                    })
                }
            }
            .onDisappear {
                showPlaidSheet = false
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        RootTabView()
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

// MARK: - 튜토리얼 종료 후 계정 연결 안내

private struct PostTutorialOverlay: View {
    let onConnect: () -> Void

    var body: some View {
        Color.black.opacity(0.80)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: Theme.spacingSection) {
                    Spacer()
                    Text("이제 실제 데이터를 연결해볼까요?")
                        .font(.custom(Theme.fontLaundry, size: Theme.titleSize))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text("지금까지 보신 화면은 데모 데이터입니다.\n계정을 연결하면 자동으로 거래 내역을 불러오고\n예산을 분석해드려요.")
                        .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    Spacer()
                    Button(action: onConnect) {
                        Text("계정 연결하고 시작하기")
                            .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.buttonVerticalPadding)
                            .background(Theme.rose)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
                    }
                    .padding(.horizontal, Theme.screenHorizontal * 2)
                    .padding(.bottom, Theme.screenBottom + 24)
                }
                .padding(.horizontal, Theme.screenHorizontal * 2)
            }
    }
}

