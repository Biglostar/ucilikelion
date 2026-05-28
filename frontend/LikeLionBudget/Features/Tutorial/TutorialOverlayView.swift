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
                Canvas { context, size in
                    context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.76)))
                    if let f = store.highlightFrame {
                        context.blendMode = .destinationOut
                        let hole = CGRect(x: f.minX - 10, y: f.minY - 10, width: f.width + 20, height: f.height + 20)
                        context.fill(Path(roundedRect: hole, cornerRadius: 14), with: .color(.black))
                    }
                }
                .ignoresSafeArea()

                calloutView(screenSize: geo.size)
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { store.advance() }
        .overlay(alignment: .topTrailing) {
            if store.currentStep != .done {
                Button("건너뛰기") { store.skip() }
                    .font(.custom(Theme.fontLaundry, size: Theme.dateLabelSize))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, 60)
                    .padding(.trailing, Theme.screenHorizontal)
            }
        }
    }

    // MARK: - 설명 카드 배치

    @ViewBuilder
    private func calloutView(screenSize: CGSize) -> some View {
        let frame = store.highlightFrame
        let step = store.currentStep
        let w = max(screenSize.width, 1)
        let h = max(screenSize.height, 1)
        let cardMaxW = max(w - Theme.screenHorizontal * 2 - 8, 100)

        // + 버튼은 항상 오른쪽 상단 고정 위치
        if step == .addTransaction {
            let btnX = screenSize.width - 36
            let btnY: CGFloat = 64
            ZStack {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.beige)
                    .position(x: btnX, y: btnY + 14)
                calloutCard(step: step)
                    .frame(maxWidth: cardMaxW)
                    .position(x: w / 2, y: btnY + 14 + 70)
            }
        } else if frame == nil {
            // welcome / done — 화면 중앙 카드
            centeredCard(step: step)
                .position(x: w / 2, y: h / 2)
        } else if let f = frame {
            let holeBottom = f.maxY + 10
            let holeTop    = f.minY - 10
            let cardH: CGFloat = 120
            let arrowH: CGFloat = 10
            let gap: CGFloat = 8
            let showBelow = holeBottom + arrowH + gap + cardH + 40 < screenSize.height

            let cardY: CGFloat = showBelow
                ? holeBottom + arrowH + gap + cardH / 2
                : holeTop - arrowH - gap - cardH / 2

            let arrowY: CGFloat = showBelow
                ? holeBottom + arrowH / 2 + 2
                : holeTop - arrowH / 2 - 2

            let clampedX = min(max(f.midX, 40), screenSize.width - 40)

            ZStack {
                // 화살표
                Image(systemName: showBelow ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.beige)
                    .position(x: clampedX, y: arrowY)

                // 설명 카드
                calloutCard(step: step)
                    .frame(maxWidth: cardMaxW)
                    .position(x: w / 2, y: cardY)
            }
        }
    }

    // MARK: - 중앙 카드 (welcome / done)

    private func centeredCard(step: TutorialStep) -> some View {
        VStack(spacing: 14) {
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
            .foregroundStyle(Theme.text.opacity(0.5))
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .background(cardBackground(cornerRadius: 16))
    }

    // MARK: - 일반 설명 카드

    private func calloutCard(step: TutorialStep) -> some View {
        VStack(spacing: 10) {
            Text(step.message)
                .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            HStack(spacing: 6) {
                Image(systemName: "hand.tap").font(.caption)
                Text("탭하여 계속")
                    .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
            }
            .foregroundStyle(Theme.text.opacity(0.5))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(cardBackground(cornerRadius: 14))
    }

    private func cardBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Theme.beige)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 4)
    }
}

// MARK: - 시트 내부용 오버레이

struct TutorialSheetOverlayView: View {
    @ObservedObject var store: TutorialStore
    let activeSteps: Set<TutorialStep>
    var txListFrame: CGRect? = nil  // editTransaction 단계용

    var body: some View {
        if store.isActive, activeSteps.contains(store.currentStep) {
            GeometryReader { geo in
                let overlayOrigin = geo.frame(in: .global).origin
                ZStack {
                    sheetSpotlight(geo: geo, overlayOrigin: overlayOrigin)
                    sheetCallout(geo: geo, overlayOrigin: overlayOrigin)
                }
            }
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { store.advance() }
            .animation(.easeInOut(duration: 0.25), value: store.currentStep)
        }
    }

    // MARK: - Spotlight

    @ViewBuilder
    private func sheetSpotlight(geo: GeometryProxy, overlayOrigin: CGPoint) -> some View {
        let step = store.currentStep
        if step == .editTransaction, let f = txListFrame {
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.76)))
                context.blendMode = .destinationOut
                // global 좌표 → overlay 로컬 좌표로 변환
                let localX = f.minX - overlayOrigin.x - 10
                let localY = f.minY - overlayOrigin.y - 10
                let hole = CGRect(x: localX, y: localY, width: f.width + 20, height: f.height + 20)
                context.fill(Path(roundedRect: hole, cornerRadius: 14), with: .color(.black))
            }
            .ignoresSafeArea()
        } else {
            Color.black.opacity(0.76).ignoresSafeArea()
        }
    }

    // MARK: - Callout

    @ViewBuilder
    private func sheetCallout(geo: GeometryProxy, overlayOrigin: CGPoint) -> some View {
        let step = store.currentStep
        let w = max(geo.size.width, 1)
        let h = max(geo.size.height, 1)
        let cardMaxW = max(w - Theme.screenHorizontal * 2, 100)

        if step == .addTransaction {
            // + 버튼 위치: 오른쪽 상단
            let btnX = w - 32
            let btnY: CGFloat = 54
            ZStack {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.beige)
                    .position(x: btnX, y: btnY + 16)
                sheetCard(step: step)
                    .frame(maxWidth: cardMaxW)
                    .position(x: w / 2, y: btnY + 16 + 72)
            }
        } else if step == .editTransaction, let f = txListFrame {
            let localBottom = f.maxY - overlayOrigin.y + 10
            let cardY = localBottom + 16 + 55
            ZStack {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.beige)
                    .position(x: w / 2, y: localBottom + 10)
                sheetCard(step: step)
                    .frame(maxWidth: cardMaxW)
                    .position(x: w / 2, y: cardY)
            }
        } else {
            // dayDetail — 중앙 카드
            sheetCard(step: step)
                .frame(maxWidth: cardMaxW)
                .position(x: w / 2, y: h / 2)
        }
    }

    private func sheetCard(step: TutorialStep) -> some View {
        VStack(spacing: 10) {
            Text(step.message)
                .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            HStack(spacing: 6) {
                Image(systemName: "hand.tap").font(.caption)
                Text("탭하여 계속")
                    .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
            }
            .foregroundStyle(Theme.text.opacity(0.5))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.beige)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1))
                .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 4)
        )
    }
}
