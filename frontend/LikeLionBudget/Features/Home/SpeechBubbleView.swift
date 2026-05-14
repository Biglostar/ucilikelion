//
//  SpeechBubbleView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/1/26.
//

import SwiftUI

struct SpeechBubbleView: View {
    let text: String

    private let strokeColor = Color.black.opacity(0.45)
    private let strokeWidth: CGFloat = 0.9
    private let corner: CGFloat = 22

    var body: some View {
        Group {
            if text.isEmpty {
                Color.clear
                    .frame(minWidth: 44, minHeight: 32)
            } else {
                Text(text)
                    .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.42)
            }
        }
        .padding(.horizontal, Theme.cardPadding)
        .padding(.vertical, Theme.spacingCompact)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(strokeColor, lineWidth: strokeWidth)
        )
        .fixedSize(horizontal: false, vertical: true)
    }
}
