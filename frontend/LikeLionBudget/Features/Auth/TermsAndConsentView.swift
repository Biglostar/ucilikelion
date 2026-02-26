//
//  TermsAndConsentView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/18/26.
//

import SwiftUI

struct TermsAndConsentView: View {
    @Environment(\.dismiss) private var dismiss
    var onAgree: (() -> Void)?

    @State private var agreedToAll = false
    @State private var showTermsSheet = false
    @State private var showPrivacySheet = false

    private let cardCorner: CGFloat = Theme.cardCorner
    private let cardBorder = Color.black.opacity(0.12)

    private let horizontalGap: CGFloat = Theme.screenHorizontal + 16

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 32)

            Text("약관 동의")
                .font(.custom(Theme.fontLaundry, size: Theme.titleSize))
                .foregroundStyle(Theme.text)

            Text("금융앱 특성상 서비스 이용을 위해 약관 및 개인정보처리방침 동의가 필요해요.")
                .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                .foregroundStyle(Theme.text.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, horizontalGap)
                .padding(.top, Theme.spacingRegular)

            VStack(spacing: Theme.spacingRegular) {
                consentRow(title: "서비스 이용약관") {
                    showTermsSheet = true
                }
                consentRow(title: "개인정보처리방침") {
                    showPrivacySheet = true
                }
            }
            .padding(.horizontal, horizontalGap)
            .padding(.top, Theme.spacingSection)

            HStack {
                Text("위 내용을 모두 읽고 동의합니다.")
                    .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                    .foregroundStyle(Theme.text)
                Spacer()
                Toggle("", isOn: $agreedToAll)
                    .tint(Theme.progressFill)
            }
            .padding(.horizontal, horizontalGap)
            .padding(.vertical, Theme.spacingRegular)
            .background(Theme.beige)
            .padding(.top, Theme.spacingSection)

            Spacer(minLength: Theme.spacingSection)

            Button {
                onAgree?()
                dismiss()
            } label: {
                Text("동의하고 계속")
                    .font(.custom(Theme.fontLaundry, size: 15))
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.buttonVerticalPadding)
                    .background(agreedToAll ? Theme.progressFill : Theme.text.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: cardCorner, style: .continuous))
            }
            .disabled(!agreedToAll)
            .buttonStyle(.plain)
            .padding(.horizontal, horizontalGap)
            .padding(.bottom, Theme.spacingSection)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.beige)
        .sheet(isPresented: $showTermsSheet) {
            NavigationStack {
                TermsPolicyView(contentType: .terms)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("닫기") { showTermsSheet = false }
                                .foregroundStyle(Theme.rose)
                        }
                    }
            }
        }
        .sheet(isPresented: $showPrivacySheet) {
            NavigationStack {
                TermsPolicyView(contentType: .privacy)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("닫기") { showPrivacySheet = false }
                                .foregroundStyle(Theme.rose)
                        }
                    }
            }
        }
    }

    private func consentRow(title: String, onView: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                .foregroundStyle(Theme.text)
            Spacer()
            Button(action: onView) {
                Text("보기")
                    .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                    .foregroundStyle(Theme.progressFill)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.cardPadding)
        .padding(.vertical, Theme.spacingRegular)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                .stroke(cardBorder, lineWidth: 1)
        )
    }
}

#Preview {
    TermsAndConsentView()
}
