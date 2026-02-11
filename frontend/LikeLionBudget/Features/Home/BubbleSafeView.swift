//
//  BubbleSafeView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/31/26.
//

import SwiftUI

struct BubbleSafeView: View {
    let text: String
    let bubbleImageName: String

    var body: some View {
        Image(bubbleImageName)
            .resizable()
            .scaledToFit()
            .overlay {
                GeometryReader { geo in
                    let textW = geo.size.width * 0.56
                    let textH = geo.size.height * 0.34

                    Text(text)
                        .font(.custom("TTLaundryGothicR", size: 13))
                        .foregroundStyle(Color(hex: "#53514E"))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.20)
                        .allowsTightening(true)
                        .frame(width: textW, height: textH)
                        .position(x: geo.size.width * 0.54,
                                  y: geo.size.height * 0.36)
                }
            }
    }
}
