//
//  GoalSpeechBubbleView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/31/26.
//

import SwiftUI

struct SpeechBubbleAutoSize: View {
    let text: String
    let bubbleImageName: String

    var body: some View {
        ZStack {
            Image(bubbleImageName)
                .resizable(
                    capInsets: EdgeInsets(top: 32, leading: 44, bottom: 32, trailing: 44),
                    resizingMode: .stretch
                )

            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
