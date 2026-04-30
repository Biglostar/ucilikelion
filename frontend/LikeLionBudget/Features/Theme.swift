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
    /// 기준(refWidth 390)에서 1.0. 화면 폭에 비례해 모든 pt 단위 스케일 (폰트·간격·패딩 등)
    static var scale: CGFloat { screenWidth / refWidth }
    static var layoutScale: CGFloat { scale }

    // MARK: - 홈 화면
    enum Home {
        /// 헤더(캐릭터+말풍선) 영역이 화면 높이에서 차지하는 비율
        static let headerRatio: CGFloat = 0.56
        /// 헤더 하단 이번달 지출 영역 높이
        static var spendAreaHeight: CGFloat { h(160) }
        static var gapHeaderToGoalBlock: CGFloat { 16 * scale }
        static var gapInsideGoalPage: CGFloat { 12 * scale }
        static var gapGoalToCalendar: CGFloat { 20 * scale }
        static var goalCalendarHorizontal: CGFloat { 20 * scale }
        static var calendarVerticalPadding: CGFloat { 4 * scale }
        /// 말풍선 너비가 화면 폭에서 차지하는 비율
        static let bubbleWidthRatio: CGFloat = 0.34
        /// 레벨 0 캐릭터 스케일
        static let characterLevel0Scale: CGFloat = 0.92
        /// 목표 게이지 바 높이
        static var goalBarHeight: CGFloat { 32 * scale }
        /// 이번달 지출 금액 폰트 사이즈
        static var spendAmountSize: CGFloat { 44 * scale }
    }

    // MARK: - 개인정보 관리 화면
    enum PersonalInfo {
        /// 카드 내부 윗쪽 빈 공간
        static var cardInternalTopClear: CGFloat { Theme.h(40) }
        /// 카드 내부 컨텐츠 위쪽 갭
        static var cardContentTop: CGFloat { Theme.h(16) }
        /// 카드 하단 패딩
        static var cardContentBottom: CGFloat { 28 * scale }
        /// 카드 박스 전체 위쪽 갭
        static var cardTop: CGFloat { Theme.h(100) }
        /// 캐릭터 이미지 너비 = 화면 - 좌우패딩
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
        static var titleBottom: CGFloat { 6 * scale }
        static var questionTop: CGFloat { Theme.h(20) }
        static var buttonTop: CGFloat { Theme.h(24) }
        static var buttonVertical: CGFloat { 16 * scale }
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

    // MARK: - Layout
    static var screenHorizontal: CGFloat { 16 * scale }
    static var screenTop: CGFloat { 14 * scale }
    static var screenTopNavExtra: CGFloat { 10 * scale }
    static var screenBottom: CGFloat { 28 * scale }
    static var cardPadding: CGFloat { 14 * scale }
    static var cardCorner: CGFloat { 10 * scale }
    static var sheetCornerRadius: CGFloat { 20 * scale }
    static var titleSize: CGFloat { 28 * scale }
    static var subscreenTitleSize: CGFloat { 22 * scale }
    static var subtitleSize: CGFloat { 18 * scale }
    static var sectionTitleSize: CGFloat { 20 * scale }
    static var dateLabelSize: CGFloat { 15 * scale }
    static var bodySize: CGFloat { 16 * scale }
    static var listTitleSize: CGFloat { 18 * scale }
    static var smallBodySize: CGFloat { 13 * scale }
    static var captionSmallSize: CGFloat { 12 * scale }

    // MARK: - 공통 간격
    static var spacingTight: CGFloat { 4 * scale }
    static var spacingSmall: CGFloat { 6 * scale }
    static var spacingCompact: CGFloat { 10 * scale }   // spacingSmall(6) + spacingTight(4) 대체
    static var spacingMedium: CGFloat { 8 * scale }
    static var spacingRegular: CGFloat { 12 * scale }
    static var spacingStandard: CGFloat { 14 * scale }
    static var spacingWide: CGFloat { 16 * scale }
    static var spacingSection: CGFloat { 20 * scale }
    static var spacingLarge: CGFloat { 18 * scale }

    // MARK: - 리스트/행 규격
    static var listRowInsetVertical: CGFloat { 8 * scale }
    static var listRowInsetVerticalCompact: CGFloat { 6 * scale }
    static var listRowInsetHorizontal: CGFloat { 16 * scale }
    static var listIconSize: CGFloat { 34 * scale }

    // MARK: - 스트로크/구분선
    static let strokeOpacityLight: Double = 0.06
    static let strokeOpacityBorder: Double = 0.07
    static let strokeOpacityMedium: Double = 0.08
    static let strokeOpacityCard: Double = 0.12
    static var strokeLineWidth: CGFloat { 1 * scale }
    static var strokeLineWidthThick: CGFloat { 1.2 * scale }
    static var strokeLineWidthCell: CGFloat { 1.8 * scale }
    static let dividerOpacity: Double = 0.10

    // MARK: - 버튼/입력 공통
    static var buttonVerticalPadding: CGFloat { 14 * scale }
    static var cardInnerHorizontal: CGFloat { 20 * scale }
    static var cardRowVertical: CGFloat { 16 * scale }
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
