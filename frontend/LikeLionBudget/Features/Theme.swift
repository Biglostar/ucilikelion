//
//  Theme.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/31/26.
//

import SwiftUI
import UIKit

enum Theme {
    // MARK: - 해상도 비율 규격
    private static let refWidth: CGFloat = 390
    private static let refHeight: CGFloat = 844
    static var screenWidth: CGFloat { UIScreen.main.bounds.width }
    static var screenHeight: CGFloat { UIScreen.main.bounds.height }
    static func h(_ pt: CGFloat) -> CGFloat { pt * screenHeight / refHeight }
    static func w(_ pt: CGFloat) -> CGFloat { pt * screenWidth / refWidth }

    // MARK: - 홈 화면
    enum Home {
        static let headerRatio: CGFloat = 0.56
        static var spendAreaHeight: CGFloat { h(160) }
        static let gapHeaderToGoalBlock: CGFloat = 16
        static let gapInsideGoalPage: CGFloat = 12
        static let gapGoalToCalendar: CGFloat = 20
        static let goalCalendarHorizontal: CGFloat = 20
        static let calendarVerticalPadding: CGFloat = 4
        static let bubbleWidthRatio: CGFloat = 0.34
        /// 레벨 0 캐릭터 스케일
        static let characterLevel0Scale: CGFloat = 0.92
    }

    // MARK: - 개인정보 관리 화면
    enum PersonalInfo {
        /// 카드 내부 윗쪽 빈 공간 (캐릭터와 겹치는 영역)
        static var cardInternalTopClear: CGFloat { Theme.h(40) }
        /// 카드 내부 컨텐츠(이름 행) 위쪽 갭
        static var cardContentTop: CGFloat { Theme.h(16) }
        /// 카드 하단 패딩
        static var cardContentBottom: CGFloat { 28 }
        /// 카드 박스 전체 위쪽 갭 (숫자 키우면 박스 아래로, 줄이면 위로)
        static var cardTop: CGFloat { Theme.h(100) }
        /// 캐릭터 이미지 너비 = 화면 - 좌우패딩 - 이 오프셋 (숫자 키우면 이미지 더 좁아짐)
        static var imageWidthOffset: CGFloat { Theme.w(56) }
        /// 캐릭터 이미지 높이
        static var imageHeight: CGFloat { Theme.h(150) }
        /// 캐릭터 이미지 위쪽 여백
        static var imageTop: CGFloat { 0 }
    }

    // MARK: - 계정 탈퇴 확인 시트
    enum AccountDeletion {
        static var sheetHeight: CGFloat { Theme.h(260) }
        static var horizontalPadding: CGFloat { Theme.w(24) }
        static var contentGap: CGFloat { Theme.h(12) }
        static var bottomPadding: CGFloat { Theme.h(10) }
        static var titleTop: CGFloat { Theme.h(24) }
        static var titleBottom: CGFloat { 6 }
        static var questionTop: CGFloat { Theme.h(20) }
        static var buttonTop: CGFloat { Theme.h(24) }
        static var buttonVertical: CGFloat { 16 }
        static var buttonSpacing: CGFloat { Theme.w(14) }
    }

    // MARK: - Colors
    static let beige = Color(llHex: "#FEF8F1")
    static let plus = Color(llHex: "#51AC90")
    static let minus  = Color(llHex: "BB5757")
    static let rose  = Color(llHex: "#A17272")
    static let text  = Color(llHex: "#53514E")
    static let progressFill = Color(llHex: "#74B19E")
    static let progressBG   = Color(llHex: "#DEF3EC")
    static let overFill = Color(llHex: "#C67576")
    static let overBG   = Color(llHex: "#F7D6D6")
    static let weekdaySimbol = Color(llHex: "#757575")

    // MARK: - Typography
    static let fontLaundry = "TTLaundryGothicR"

    // MARK: - Layout (메인 화면 규격 통일)
    /// 스크롤 화면 좌우 여백
    static let screenHorizontal: CGFloat = 16
    /// 스크롤 화면 상단 여백
    static let screenTop: CGFloat = 14
    /// 네비 타이틀 화면
    static let screenTopNavExtra: CGFloat = 10
    /// 스크롤 화면 하단 여백
    static let screenBottom: CGFloat = 28
    /// 카드/컨테이너 내부 패딩
    static let cardPadding: CGFloat = 14
    /// 카드 모서리
    static let cardCorner: CGFloat = 10
    /// 탭/메인 타이틀
    static let titleSize: CGFloat = 30
    /// 서브 타이틀/시트 제목
    static let subtitleSize: CGFloat = 18
    /// 섹션 제목
    static let sectionTitleSize: CGFloat = 20
    /// 날짜/부제목
    static let dateLabelSize: CGFloat = 15
    /// 섹션/라벨 본문
    static let bodySize: CGFloat = 16
    /// 리스트 금액/제목 등 (DayDetail, Report)
    static let listTitleSize: CGFloat = 18
    /// 작은 본문
    static let smallBodySize: CGFloat = 13
    /// 캡션/보조 라벨
    static let captionSmallSize: CGFloat = 12

    // MARK: - 공통 간격
    static let spacingTight: CGFloat = 4
    static let spacingSmall: CGFloat = 6
    static let spacingMedium: CGFloat = 8
    static let spacingRegular: CGFloat = 12
    static let spacingStandard: CGFloat = 14
    static let spacingWide: CGFloat = 16
    static let spacingSection: CGFloat = 20
    static let spacingLarge: CGFloat = 18

    // MARK: - 리스트/행 규격
    static let listRowInsetVertical: CGFloat = 8
    static let listRowInsetVerticalCompact: CGFloat = 6
    static let listRowInsetHorizontal: CGFloat = 16
    static let listIconSize: CGFloat = 34

    // MARK: - 스트로크/구분선
    static let strokeOpacityLight: Double = 0.06
    static let strokeOpacityBorder: Double = 0.07
    static let strokeOpacityMedium: Double = 0.08
    static let strokeOpacityCard: Double = 0.12
    static let strokeLineWidth: CGFloat = 1
    static let strokeLineWidthThick: CGFloat = 1.2
    static let strokeLineWidthCell: CGFloat = 1.8
    static let dividerOpacity: Double = 0.10

    // MARK: - 버튼/입력 공통
    static let buttonVerticalPadding: CGFloat = 14
    /// 카드 내부 좌우 패딩
    static let cardInnerHorizontal: CGFloat = 20
    /// 카드 내부 세로 패딩
    static let cardRowVertical: CGFloat = 16
    /// 차트 플레이스홀더 높이
    static var chartPlaceholderHeight: CGFloat { h(160) }
}


extension Color {
    init(llHex: String) {
        let hex = llHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
