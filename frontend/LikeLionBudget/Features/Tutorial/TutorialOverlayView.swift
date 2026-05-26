//
//  TutorialOverlayView.swift
//  LikeLionBudget
//

import SwiftUI
import Combine

// MARK: - 홈·목표·리포트 화면용 Spotlight 오버레이

struct TutorialOverlayView: View {
    @ObservedObject var store: TutorialStore

    var body: some View {
        GeometryReader { geo in
            ZStack {
                spotlightLayer(size: geo.size)
                calloutLayer(size: geo.size)
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
        .animation(.easeInOut(duration: 0.3), value: store.currentStep)
    }

    // MARK: - Spotlight (dim + hole)

    private func spotlightLayer(size: CGSize) -> some View {
        let frame = store.highlightFrame

        return ZStack {
            Color.black.opacity(0.75)
            if let f = frame {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .frame(width: f.width + 20, height: f.height + 20)
                    .position(x: f.midX, y: f.midY)
                    .blendMode(.destinationOut)
            }
        }
        .compositingGroup()
        .ignoresSafeArea()
    }

    // MARK: - Callout (설명 카드 + 화살표)

    private func calloutLayer(size: CGSize) -> some View {
        let frame = store.highlightFrame
        let step = store.currentStep

        return Group {
            if frame == nil {
                // welcome / done — 중앙 카드
                centeredCard(step: step, size: size)
            } else if let f = frame {
                positionedCallout(step: step, frame: f, size: size)
            }
        }
    }

    // MARK: - 중앙 카드 (welcome / done)

    private func centeredCard(step: TutorialStep, size: CGSize) -> some View {
        VStack(spacing: 16) {
            Text(step.message)
                .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            HStack(spacing: 6) {
                Image(systemName: step == .done ? "checkmark.circle" : "hand.tap")
                    .font(.caption)
                Text(step == .done ? "시작하기" : "탭하여 계속")
                    .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
            }
            .foregroundStyle(Theme.text.opacity(0.55))
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 28)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.beige)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 4)
        .padding(.horizontal, Theme.screenHorizontal + 8)
        .position(x: size.width / 2, y: size.height / 2)
    }

    // MARK: - 위치 기반 callout

    private func positionedCallout(step: TutorialStep, frame: CGRect, size: CGSize) -> some View {
        let holeTop = frame.minY - 10
        let holeBottom = frame.maxY + 10
        let cardHeight: CGFloat = 110
        let arrowSize: CGFloat = 10
        let margin: CGFloat = 12

        // 구멍 아래에 공간이 충분하면 아래에, 아니면 위에
        let showBelow = holeBottom + cardHeight + arrowSize + margin < size.height - 40

        let cardY: CGFloat = showBelow
            ? holeBottom + arrowSize + cardHeight / 2 + margin
            : holeTop - arrowSize - cardHeight / 2 - margin

        return ZStack {
            // 화살표
            Image(systemName: showBelow ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                .font(.system(size: arrowSize))
                .foregroundStyle(Theme.beige)
                .position(
                    x: min(max(frame.midX, 40), size.width - 40),
                    y: showBelow ? holeBottom + margin : holeTop - margin
                )

            // 설명 카드
            VStack(spacing: 10) {
                Text(step.message)
                    .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                HStack(spacing: 6) {
                    Image(systemName: "hand.tap")
                        .font(.caption)
                    Text("탭하여 계속")
                        .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                }
                .foregroundStyle(Theme.text.opacity(0.55))
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .frame(maxWidth: size.width - Theme.screenHorizontal * 2 - 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.beige)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 3)
            .position(x: size.width / 2, y: cardY)
        }
    }
}

// MARK: - 시트 내부용 단순 오버레이

struct TutorialSheetOverlayView: View {
    @ObservedObject var store: TutorialStore
    let activeSteps: Set<TutorialStep>

    var body: some View {
        if store.isActive, activeSteps.contains(store.currentStep) {
            GeometryReader { geo in
                ZStack {
                    // dim
                    Color.black.opacity(0.75)
                        .ignoresSafeArea()

                    // 설명 카드
                    VStack(spacing: 10) {
                        Text(store.currentStep.message)
                            .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                            .foregroundStyle(Theme.text)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)

                        HStack(spacing: 6) {
                            Image(systemName: "hand.tap").font(.caption)
                            Text("탭하여 계속")
                                .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                        }
                        .foregroundStyle(Theme.text.opacity(0.55))
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.beige)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                    )
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 3)
                    .padding(.horizontal, Theme.screenHorizontal)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { store.advance() }
            .animation(.easeInOut(duration: 0.25), value: store.currentStep)
        }
    }
}
