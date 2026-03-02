//
//  View+CardStyle.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/22/26.
//

import SwiftUI
import UIKit

func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

extension View {
    // MARK: - Base Card
    func cardStyle(
        bg: Color = .white,
        corner: CGFloat = Theme.cardCorner,
        strokeOpacity: Double = Theme.strokeOpacityMedium,
        padding: CGFloat = Theme.screenHorizontal
    ) -> some View {
        self
            .padding(padding)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.black.opacity(strokeOpacity))
            )
    }

    // MARK: - App Rules
    func llScreen() -> some View {
        self
            .background(Color.white)
    }

    func llContainer(corner: CGFloat = Theme.cardCorner) -> some View {
        self
            .padding(Theme.cardPadding)
            .background(Theme.beige)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.black.opacity(Theme.strokeOpacityLight))
            )
    }

    func llCard(corner: CGFloat = Theme.cardCorner, padding: CGFloat = Theme.cardPadding) -> some View {
        self.cardStyle(
            bg: Theme.progressBG,
            corner: corner,
            strokeOpacity: Theme.strokeOpacityLight,
            padding: padding
        )
    }

    func llDivider(opacity: Double = Theme.dividerOpacity) -> some View {
        self.overlay(
            Rectangle().frame(height: 1).foregroundStyle(Color.black.opacity(opacity)),
            alignment: .bottom
        )
    }

    // MARK: - Backward compat
    func beigeContainer(corner: CGFloat = Theme.cardCorner) -> some View {
        self.llContainer(corner: corner)
    }

    func softDividerBox(corner: CGFloat = Theme.cardCorner) -> some View {
        self
            .padding(.vertical, Theme.spacingSmall + 4)
            .padding(.horizontal, Theme.spacingRegular)
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.black.opacity(Theme.strokeOpacityBorder))
            )
    }

    // MARK: - Navigation Title (Toolbar Principal)

    func llNavTitle(_ title: String) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.custom(Theme.fontLaundry, size: Theme.titleSize))
                        .foregroundStyle(Theme.rose)
                }
            }
    }
}
