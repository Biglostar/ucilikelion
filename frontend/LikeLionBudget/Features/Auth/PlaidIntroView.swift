//
//  PlaidIntroView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/18/26.
//

import SwiftUI
import UIKit

/// Plaid 지정 개인정보처리방침 URL
private let plaidPrivacyPolicyURL = URL(string: "https://plaid.com/legal/#privacy-policy")!

private let plaidLogoImageName = "PlaidLogo"
private let plaidCardBorder = Color(hex: "#B3B3B3")
private let plaidSubtitle = Color(hex: "#9C9797")

struct PlaidIntroView: View {
    @Environment(\.dismiss) private var dismiss
    var onContinue: (() -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer(minLength: 24)
            VStack(spacing: 0) {
                logoPlaceholder
                mainTitle
            }
            .padding(.top, -20)
            featureSection
            Spacer(minLength: Theme.spacingSection)
            privacyText
            continueButton
                .padding(.bottom, 18)
        }
        .padding(.horizontal, Theme.screenHorizontal)
        .padding(.top, Theme.spacingRegular)
        .padding(.bottom, Theme.spacingSection)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .ignoresSafeArea(.all)
    }

    // MARK: - Subviews (header / logo / featureSection / continueButton)

    private var header: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.black)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
    }

    private var logoPlaceholder: some View {
        Group {
            if UIImage(named: plaidLogoImageName) != nil {
                Image(plaidLogoImageName)
                    .resizable()
                    .scaledToFit()
            } else {
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .fill(Color(white: 0.95))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundStyle(plaidSubtitle)
                    )
            }
        }
        .frame(width: 52, height: 52)
        .padding(.top, Theme.spacingRegular)
    }

    private var mainTitle: some View {
        Text("꼽주머니는 Plaid를 통해 계정을 연결합니다")
            .font(.custom(Theme.fontLaundry, size: Theme.subtitleSize))
            .fontWeight(.semibold)
            .foregroundStyle(Color.black)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.top, Theme.spacingSection)
    }

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingRegular) {
            featureRow(
                icon: "bolt.fill",
                title: "단 몇 초 만에 간편 연결",
                subtitle: "8000개 이상의 앱이 Plaid를 사용해 금융기관과 빠르게 연결하고 있습니다"
            )
            featureRow(
                icon: "checkmark.shield.fill",
                title: "데이터를 안전하게 보호합니다",
                subtitle: "Plaid는 최고 수준의 암호화를 사용해 고객님의 데이터를 보호합니다",
                singleLine: true
            )
        }
        .padding(Theme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .stroke(plaidCardBorder, lineWidth: Theme.strokeLineWidth)
        )
        .padding(.top, Theme.spacingStandard)
    }

    private func featureRow(icon: String, title: String, subtitle: String, singleLine: Bool = false) -> some View {
        HStack(alignment: .top, spacing: Theme.spacingRegular) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Theme.progressFill)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.black)
                Text(subtitle)
                    .font(.custom(Theme.fontLaundry, size: Theme.captionSmallSize))
                    .foregroundStyle(plaidSubtitle)
                    .lineLimit(singleLine ? 1 : 2)
                    .minimumScaleFactor(singleLine ? 0.7 : 1)
            }
        }
    }

    private var privacyText: some View {
        HStack(spacing: Theme.spacingTight) {
            Text("계속 진행하면 ")
                .font(.custom(Theme.fontLaundry, size: Theme.captionSmallSize))
                .foregroundStyle(plaidSubtitle)
            Link("Plaid의 개인정보처리방침", destination: plaidPrivacyPolicyURL)
                .font(.custom(Theme.fontLaundry, size: Theme.captionSmallSize))
                .tint(Theme.progressFill)
            Text("에 동의하는 것으로 간주됩니다")
                .font(.custom(Theme.fontLaundry, size: Theme.captionSmallSize))
                .foregroundStyle(plaidSubtitle)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal)
        .padding(.bottom, Theme.spacingRegular)
    }

    private var continueButton: some View {
        Button {
            onContinue?()
        } label: {
            Text("계속하기")
                .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.buttonVerticalPadding)
                .background(Theme.progressFill)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
