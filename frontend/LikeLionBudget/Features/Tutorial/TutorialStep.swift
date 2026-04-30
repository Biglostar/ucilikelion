//
//  TutorialStep.swift
//  LikeLionBudget
//
//  Created by samuel kim on 4/9/26.
//

import Foundation

enum TutorialStep: Int, CaseIterable, Hashable {

    // MARK: - 홈 탭
    case welcome = 0
    case character
    case speechBubble
    case spendAmount
    case goalProgress
    case calendar
    case dayDetail          // HomeView → DayDetailSheet 자동 오픈
    case addTransaction     // DayDetailSheet → TransactionEditorView(.add) 자동 오픈
    case editTransaction    // DayDetailSheet → TransactionEditorView(.edit) 자동 오픈

    // MARK: - 목표 탭
    case goalsList
    case goalToggle
    case addGoal

    // MARK: - 리포트 탭
    case monthlyReport      // 카드 자동 펼치기
    case fixedCosts         // 카드 자동 펼치기

    case done

    // MARK: - 이미지 이름 (Tutorial 1 ~ Tutorial 15)

    var imageName: String {
        return "Tutorial \(rawValue + 1)"
    }

    // MARK: - 표시 메시지

    var message: String {
        switch self {
        case .welcome:
            return "꼽주머니에 오신 걸 환영해요!\n주요 기능을 안내해드릴게요."
        case .character:
            return "지출이 늘어날수록 캐릭터 표정과\n방 상태가 점점 변해요."
        case .speechBubble:
            return "말풍선 속 멘트는 소비 습관에 따라\nAI가 맞춤으로 남겨줘요."
        case .spendAmount:
            return "이번 달 총 지출 금액을\n여기서 한눈에 볼 수 있어요."
        case .goalProgress:
            return "목표별 남은 예산을\n게이지로 확인할 수 있어요."
        case .calendar:
            return "달력에서 날짜별 수입·지출\n흐름을 확인하세요."
        case .dayDetail:
            return "날짜를 탭하면 그날의\n거래 내역을 볼 수 있어요."
        case .addTransaction:
            return "오른쪽 상단 + 버튼으로\n새 거래를 추가할 수 있어요."
        case .editTransaction:
            return "거래 내역을 탭하면\n수정 화면으로 이동해요."
        case .goalsList:
            return "설정한 목표들을\n여기서 한눈에 관리할 수 있어요."
        case .goalToggle:
            return "토글로 목표를 홈 화면에\n표시하거나 숨길 수 있어요."
        case .addGoal:
            return "이 버튼으로 새로운 목표를\n추가해보세요."
        case .monthlyReport:
            return "월간 리포트에서 카테고리별\n지출 비중을 확인할 수 있어요."
        case .fixedCosts:
            return "매월 반복되는 고정 지출을\n자동으로 감지해드려요."
        case .done:
            return "이제 꼽주머니를 자유롭게 사용해보세요!"
        }
    }

    // MARK: - 탭 인덱스 (RootTabView 기준: 홈=0, 목표=1, 리포트=2)

    var requiredTab: Int {
        switch self {
        case .welcome, .character, .speechBubble, .spendAmount,
             .goalProgress, .calendar, .dayDetail, .addTransaction, .editTransaction:
            return 0
        case .goalsList, .goalToggle, .addGoal:
            return 1
        case .monthlyReport, .fixedCosts, .done:
            return 2
        }
    }

    // MARK: -

    var next: TutorialStep {
        TutorialStep(rawValue: rawValue + 1) ?? .done
    }
}
