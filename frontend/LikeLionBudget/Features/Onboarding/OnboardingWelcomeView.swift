//
//  OnboardingWelcomeView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/16/26.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    @ObservedObject var store: OnboardingStore

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Theme.rose)

                Spacer().frame(height: Theme.spacingSection)

                Text("라이크라이언 예산")
                    .font(.custom(Theme.fontLaundry, size: Theme.titleSize))
                    .foregroundStyle(Theme.text)

                Spacer().frame(height: Theme.h(60))

                Button {
                    store.startTutorial()
                } label: {
                    Text("튜토리얼 시작")
                        .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.buttonVerticalPadding)
                        .background(Theme.rose)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
                }
                .padding(.horizontal, Theme.screenHorizontal)
                .padding(.bottom, Theme.screenBottom + Theme.h(40))
            }
        }
    }
}
