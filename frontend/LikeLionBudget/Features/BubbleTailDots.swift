//
//  BubbleTailDots.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/1/26.
//

import SwiftUI

struct BubbleTailDots: View {
    private let strokeColor = Color.black.opacity(0.45)
    private let strokeWidth: CGFloat = 0.9

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.white)
                .frame(width: 18, height: 9)
                .overlay(Ellipse().stroke(strokeColor, lineWidth: strokeWidth))
                .offset(x: 4, y: -5)

            Ellipse()
                .fill(Color.white)
                .frame(width: 12, height: 5)
                .overlay(Ellipse().stroke(strokeColor, lineWidth: strokeWidth))
                .offset(x: -9, y: 5)
        }
        .padding(2)
    }
}
