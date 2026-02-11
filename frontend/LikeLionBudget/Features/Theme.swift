//
//  Theme.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/31/26.
//

import SwiftUI

enum Theme {
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

    static let fontLaundry = "TTLaundryGothicR"
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
