//
//  OnboardingStore.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/18/26.
//

import SwiftUI
import Combine

struct OnboardingStepConfig {
    let step: Int
    let message: String
    let tabIndex: Int?
    var opensDayDetail: Bool { step == 6 }
}

final class OnboardingStore: ObservableObject {
    private let defaults = UserDefaults.standard
    private let keySeenWelcome = "onboarding.hasSeenWelcome"
    private let keyCompleted = "onboarding.hasCompleted"
    private let keyPostOnboardingDone = "onboarding.postOnboardingDone"

    @Published var hasSeenWelcome: Bool {
        didSet { defaults.set(hasSeenWelcome, forKey: keySeenWelcome) }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: keyCompleted) }
    }
    @Published var currentStep: Int
    @Published var requestOpenDayDetailAt: Date?
    @Published var requestShowAddTransaction: Bool = false
    @Published var addTransactionSheetOpenedForStep6: Bool = false
    @Published var requestShowAddGoal: Bool = false
    @Published var tutorialTabIndex: Int
    @Published var collectedOnboardingFrames: [Int: [CGRect]] = [:]
    @Published var showPostTutorialScreen: Bool = false
    @Published var showLoginAfterTutorial: Bool = false

    @Published var useScreenshotTutorial: Bool = false

    /// 디버깅 true면 앱 시작 시마다 튜토리얼 시작, 릴리즈 시 false.
    static var debugAlwaysStartFromTutorial: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    var isWelcomeScreen: Bool { !hasSeenWelcome }
    var isTutorialActive: Bool { hasSeenWelcome && !hasCompletedOnboarding && currentStep >= 0 && currentStep <= 12 }
    /// 목표/거래 시드 데이터는 step 1부터만 표시. step 0(처음 화면)에서는 빈 화면.
    var showTutorialSeedData: Bool { hasSeenWelcome && !hasCompletedOnboarding && currentStep >= 1 && currentStep <= 12 }
    var hasCompletedPostOnboardingFlow: Bool {
        get { defaults.bool(forKey: keyPostOnboardingDone) }
        set { defaults.set(newValue, forKey: keyPostOnboardingDone) }
    }

    static let steps: [OnboardingStepConfig] = [
        OnboardingStepConfig(step: 1, message: "이번 달 소비 상태를 한눈에 봐요", tabIndex: 0),
        OnboardingStepConfig(step: 2, message: "지출이 늘어날수록 말풍선 속 멘트가 점점 단호해져요", tabIndex: nil),
        OnboardingStepConfig(step: 3, message: "당신의 소비 습관에 따라 이 방의 모습이 변하게 됩니다", tabIndex: nil),
        OnboardingStepConfig(step: 4, message: "목표별 진행을 스와이프로 확인", tabIndex: nil),
        OnboardingStepConfig(step: 5, message: "날짜를 누르면 그날 거래를 확인/추가할 수 있어요", tabIndex: nil),
        OnboardingStepConfig(step: 6, message: "거래 내역을 추가해요", tabIndex: nil),
        OnboardingStepConfig(step: 7, message: "거래를 눌러 수정할 수 있어요", tabIndex: nil),
        OnboardingStepConfig(step: 8, message: "목표 사용/알림을 관리", tabIndex: 2),
        OnboardingStepConfig(step: 9, message: "토글 on/off로 보기 및 알림설정을 한번에 관리", tabIndex: nil),
        OnboardingStepConfig(step: 10, message: "목표 추가 (예산은 AI가 설정해요)", tabIndex: nil),
        OnboardingStepConfig(step: 11, message: "카테고리/기간별 소비를 확인", tabIndex: 1),
        OnboardingStepConfig(step: 12, message: "고정지출을 한눈에 볼 수 있어요", tabIndex: nil),
    ]

    init() {
        if Self.debugAlwaysStartFromTutorial {
            self.hasSeenWelcome = false
            self.hasCompletedOnboarding = false
        } else {
            self.hasSeenWelcome = defaults.bool(forKey: keySeenWelcome)
            self.hasCompletedOnboarding = defaults.bool(forKey: keyCompleted)
        }
        self.currentStep = 0
        self.requestOpenDayDetailAt = nil
        self.tutorialTabIndex = 0
    }

    func config(for step: Int) -> OnboardingStepConfig? {
        OnboardingStore.steps.first { $0.step == step }
    }

    func startTutorial() {
        hasSeenWelcome = true
        currentStep = 0
        tutorialTabIndex = 0
        requestOpenDayDetailAt = nil
        collectedOnboardingFrames = [:]
    }

    func mergeOnboardingFrames(_ dict: [Int: [CGRect]]) {
        for (k, v) in dict {
            collectedOnboardingFrames[k] = v
        }
    }

    func advance() {
        if currentStep == 0 {
            currentStep = 1
            return
        }
        guard currentStep >= 1, currentStep <= 12 else { return }
        if currentStep == 12 {
            finish()
            return
        }
        if !useScreenshotTutorial {
            if currentStep == 6 {
                requestShowAddTransaction = true
                addTransactionSheetOpenedForStep6 = true
                return
            }
            if currentStep == 10 {
                requestShowAddGoal = true
                return
            }
        }
        let next = currentStep + 1
        if let cfg = config(for: next), let tab = cfg.tabIndex {
            tutorialTabIndex = tab
        }
        if next == 6 {
            requestOpenDayDetailAt = Date()
        }
        currentStep = next
    }

    private static let keyGoalsForClear = "LikeLionBudget.Goals.v1"

    func finish() {
        currentStep = 0
        hasCompletedOnboarding = true
        requestOpenDayDetailAt = nil
        collectedOnboardingFrames = [:]
        UserDefaults.standard.removeObject(forKey: Self.keyGoalsForClear)
        let shouldShowPost = !hasCompletedPostOnboardingFlow || (Self.debugAlwaysStartFromTutorial)
        if shouldShowPost {
            DispatchQueue.main.async { [weak self] in
                self?.showPostTutorialScreen = true
            }
        }
    }

    func proceedFromPostTutorialToLogin() {
        showPostTutorialScreen = false
        showLoginAfterTutorial = true
    }

    func advanceFromAddTransactionSheet() {
        guard currentStep == 6 else { return }
        addTransactionSheetOpenedForStep6 = false
        currentStep = 7
        if let cfg = config(for: 7), let tab = cfg.tabIndex { tutorialTabIndex = tab }
    }

    func advanceFromAddGoalSheet() {
        guard currentStep == 10 else { return }
        currentStep = 11
        if let cfg = config(for: 11), let tab = cfg.tabIndex { tutorialTabIndex = tab }
    }

    func skip() {
        finish()
    }

    func goBack() {
        guard currentStep > 0 else { return }
        let prev = currentStep - 1
        if currentStep == 6 {
            requestOpenDayDetailAt = nil
            requestShowAddTransaction = false
            addTransactionSheetOpenedForStep6 = false
        }
        if currentStep == 10 {
            requestShowAddGoal = false
        }
        if let cfg = config(for: prev), let tab = cfg.tabIndex {
            tutorialTabIndex = tab
        } else if prev == 10 {
            tutorialTabIndex = 2
        } else if prev == 7 {
            tutorialTabIndex = 0
        }
        currentStep = prev
    }

    func markPostOnboardingDone() {
        hasCompletedPostOnboardingFlow = true
        showLoginAfterTutorial = false
    }

    func resetPostOnboardingForReLogin() {
        hasCompletedPostOnboardingFlow = false
        showPostTutorialScreen = false
        showLoginAfterTutorial = true
    }
}
