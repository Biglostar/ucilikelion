//
//  TutorialOverlayView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 4/9/26.
//

import SwiftUI
import Combine

// MARK: - 홈·목표·리포트 화면용 Spotlight 오버레이

/// 화면 전체에 깔리는 Spotlight 튜토리얼 오버레이.
/// frames 는 .global 좌표 기준으로 등록된 값을 사용.
struct TutorialOverlayView: View {
    @ObservedObject var store: TutorialStore

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.opacity(0.78)
                    .ignoresSafeArea()
                tutorialCard(size: geo.size)
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { store.advance() }
        .overlay(alignment: .topTrailing) {
            if store.currentStep != .done {
                Button("건너뛰기") { store.skip() }
                    .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.top, 56)
                    .padding(.trailing, Theme.screenHorizontal)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.currentStep)
    }

    // MARK: - 튜토리얼 카드 (이미지 + 메시지)

    private func tutorialCard(size: CGSize) -> some View {
        VStack(spacing: 20) {
            Image(store.currentStep.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: size.width * 0.86)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner + 2, style: .continuous))
                .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)

            VStack(spacing: Theme.spacingSmall) {
                Text(store.currentStep.message)
                    .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                HStack(spacing: Theme.spacingTight) {
                    Image(systemName: store.currentStep == .done ? "checkmark.circle" : "hand.tap")
                        .font(.caption)
                    Text(store.currentStep == .done ? "시작하기" : "탭하여 계속")
                        .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                }
                .foregroundStyle(.white.opacity(0.65))
            }
            .padding(.horizontal, Theme.cardPadding + 4)
        }
        .padding(.horizontal, Theme.screenHorizontal)
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - 시트 내부용 단순 오버레이

/// DayDetailSheet, TransactionEditorView 안에서 사용하는 오버레이.
/// 시트는 모달이라 spotlight 없이 어두운 배경 + 메시지만 표시.
struct TutorialSheetOverlayView: View {
    @ObservedObject var store: TutorialStore
    /// 이 오버레이가 활성화되는 단계 집합
    let activeSteps: Set<TutorialStep>

    var body: some View {
        if store.isActive, activeSteps.contains(store.currentStep) {
            GeometryReader { geo in
                ZStack {
                    Color.black.opacity(0.78)
                        .ignoresSafeArea()

                    VStack(spacing: 20) {
                        Image(store.currentStep.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: geo.size.width * 0.86)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner + 2, style: .continuous))
                            .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)

                        VStack(spacing: Theme.spacingSmall) {
                            Text(store.currentStep.message)
                                .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)

                            HStack(spacing: Theme.spacingTight) {
                                Image(systemName: "hand.tap").font(.caption)
                                Text("탭하여 계속")
                                    .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                            }
                            .foregroundStyle(.white.opacity(0.65))
                        }
                        .padding(.horizontal, Theme.cardPadding + 4)
                    }
                    .padding(.horizontal, Theme.screenHorizontal)
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { store.advance() }
            .animation(.easeInOut(duration: 0.25), value: store.currentStep)
        }
    }
}
