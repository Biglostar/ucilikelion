//
//  View+CardStyle.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/22/26.
//

import SwiftUI

extension View {

    // MARK: - Base Card (기존 유지)
    func cardStyle(
        bg: Color = .white,
        corner: CGFloat = 18,
        strokeOpacity: Double = 0.08,
        padding: CGFloat = 16
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

    func llContainer(corner: CGFloat = 8) -> some View {
        self
            .padding(14)
            .background(Theme.beige)
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.black.opacity(0.06))
            )
    }

    func llCard(corner: CGFloat = 8, padding: CGFloat = 14) -> some View {
        self.cardStyle(
            bg: Theme.progressBG,
            corner: corner,
            strokeOpacity: 0.06,
            padding: padding
        )
    }

    func llDivider(opacity: Double = 0.10) -> some View {
        self.overlay(
            Rectangle().frame(height: 1).foregroundStyle(Color.black.opacity(opacity)),
            alignment: .bottom
        )
    }

    // MARK: - Backward compat
    func beigeContainer(corner: CGFloat = 8) -> some View {
        self.llContainer(corner: corner)
    }

    func softDividerBox(corner: CGFloat = 8) -> some View {
        self
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.black.opacity(0.07))
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
                        .font(.custom(Theme.fontLaundry, size: 22))
                        .foregroundStyle(Theme.progressFill)
                }
            }
    }
}
