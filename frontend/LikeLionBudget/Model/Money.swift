//
//  Money.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import Foundation

enum Money {

    static let usdFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.locale = Locale(identifier: "en_US")
        return f
    }()
    
    static func usdString(fromCents cents: Int) -> String {
        let amount = Decimal(cents) / 100
        return usdFormatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }

    static func usdSignedString(fromCents cents: Int) -> String {
        let absStr = usdString(fromCents: abs(cents))
        if cents > 0 { return "+\(absStr)" }
        if cents < 0 { return "-\(absStr)" }
        return absStr
    }

    /// - Parameter amountWon
    static func wonString(amountWon: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "ko_KR")
        let num = abs(amountWon)
        return (formatter.string(from: NSNumber(value: num)) ?? "\(num)") + " 원"
    }

    static func wonString(fromUsdCents cents: Int) -> String {
        let won = cents * 13 / 100
        return wonString(amountWon: won)
    }
}
