//
//  AppFormatters.swift
//  LikeLionBudget
//
//  Created by samuel kim on 4/9/26.
//

import Foundation

enum AppFormatters {
    /// "M월 d일" — 거래 날짜 표시 (한국어)
    static let koDayMonth: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f
    }()

    /// "HH:mm" — 거래 시각 표시 (한국어)
    static let koTime: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "HH:mm"
        return f
    }()

    /// "MMMM yyyy" — 캘린더 월 헤더 (영어)
    static let enMonthYear: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    /// "yyyy-MM-dd" — API 쿼리 파라미터용
    static let apiDate: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
