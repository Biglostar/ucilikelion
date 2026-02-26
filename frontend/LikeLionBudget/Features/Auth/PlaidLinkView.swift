//
//  PlaidLinkView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/18/26.
//

import SwiftUI

struct PlaidLinkView: View {
    @Environment(\.dismiss) private var dismiss
    var onComplete: (() -> Void)?

    var body: some View {
        VStack(spacing: Theme.spacingSection) {
            Text("은행 연결")
                .font(.custom(Theme.fontLaundry, size: Theme.titleSize))
                .foregroundStyle(Theme.text)
            Text("Plaid를 통해 계정을 연결합니다.\n연동 준비가 되면 이 화면에서 은행을 선택해 연결할 수 있습니다.")
                .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                .foregroundStyle(Theme.text.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer(minLength: Theme.spacingSection)
            Button {
                onComplete?()
                dismiss()
            } label: {
                Text("다음")
                    .font(.custom(Theme.fontLaundry, size: 15))
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.buttonVerticalPadding)
                    .background(Theme.progressFill)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.screenHorizontal)
            .padding(.bottom, Theme.spacingSection)
        }
        .padding(.top, Theme.spacingSection)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.beige)
    }
}

#Preview {
    PlaidLinkView()
}
