//
//  TutorialStore.swift
//  LikeLionBudget
//
//  Created by samuel kim on 4/9/26.
//

import SwiftUI
import Combine

@MainActor
final class TutorialStore: ObservableObject {

    // MARK: - 현재 상태

    @Published var isActive: Bool = false
    @Published var currentStep: TutorialStep = .welcome

    // MARK: - Frame 레지스트리 (.global 좌표 기준)
    // 각 뷰가 onAppear 시 자신의 글로벌 프레임을 등록

    @Published var frames: [TutorialStep: CGRect] = [:]

    // MARK: - 시트 / 확장 트리거
    // HomeView 가 관찰: DayDetailSheet 자동 오픈
    @Published var shouldOpenDayDetail: Bool = false
    // DayDetailSheet 가 관찰: TransactionEditorView(.add) 자동 오픈
    @Published var shouldOpenAddTransaction: Bool = false
    // DayDetailSheet 가 관찰: TransactionEditorView(.edit) 자동 오픈
    @Published var shouldOpenEditTransaction: Bool = false
    // HomeView 가 관찰: DayDetailSheet 닫기 (goalsList 전환 전)
    @Published var shouldDismissHomeSheet: Bool = false
    // ReportView 가 관찰
    @Published var shouldExpandMonthlyReport: Bool = false
    @Published var shouldExpandFixedCosts: Bool = false

    // MARK: - 영속성

    private let completedKey = "tutorial_hasCompleted_v1"

    var hasCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: completedKey) }
        set { UserDefaults.standard.set(newValue, forKey: completedKey) }
    }

    // MARK: - Public API

    /// 미완료 상태일 때만 시작. 앱 최초 진입 후 호출.
    func startIfNeeded() {
        guard !hasCompleted else { return }
        start()
    }

    func start() {
        frames = [:]
        currentStep = .welcome
        isActive = true
    }

    func advance() {
        // done 단계에서 탭하면 튜토리얼 종료
        guard currentStep != .done else { finish(); return }
        let next = currentStep.next
        currentStep = next
        if next != .done {
            handleSideEffects(for: next)
        }
    }

    func skip() { finish() }

    func registerFrame(_ frame: CGRect, for step: TutorialStep) {
        frames[step] = frame
    }

    // MARK: - Computed

    /// 현재 단계의 spotlight 프레임. welcome 은 전체 어둠(nil).
    var highlightFrame: CGRect? {
        guard currentStep != .welcome else { return nil }
        return frames[currentStep]
    }

    // MARK: - Private

    private func finish() {
        isActive = false
        hasCompleted = true
        currentStep = .welcome
        resetTriggers()
    }

    private func resetTriggers() {
        shouldOpenDayDetail = false
        shouldOpenAddTransaction = false
        shouldOpenEditTransaction = false
        shouldDismissHomeSheet = false
        shouldExpandMonthlyReport = false
        shouldExpandFixedCosts = false
    }

    private func handleSideEffects(for step: TutorialStep) {
        switch step {
        case .dayDetail:
            shouldOpenDayDetail = true
        case .addTransaction:
            shouldOpenAddTransaction = true
        case .editTransaction:
            shouldOpenEditTransaction = true
        case .goalsList:
            // DayDetailSheet 및 HomeView 시트 닫기 → RootTabView가 탭 전환
            shouldDismissHomeSheet = true
        case .monthlyReport:
            shouldExpandMonthlyReport = true
        case .fixedCosts:
            shouldExpandFixedCosts = true
        default:
            break
        }
    }
}
