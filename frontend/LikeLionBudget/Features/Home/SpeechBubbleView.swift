//
//  SpeechBubbleView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/1/26.
//

import SwiftUI

struct SpeechBubbleView: View {
    let text: String

    private let textColor = Color(red: 0x53/255, green: 0x51/255, blue: 0x4E/255)
    private let strokeColor = Color.black.opacity(0.45)
    private let strokeWidth: CGFloat = 0.9
    private let corner: CGFloat = 22

    var body: some View {
        Text(text)
            .font(.custom("TTLaundryGothicR", size: 13))
            .foregroundStyle(textColor)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.42)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
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
