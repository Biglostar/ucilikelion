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
}
