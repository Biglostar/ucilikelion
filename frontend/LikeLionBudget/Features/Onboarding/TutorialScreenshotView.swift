//
//  TutorialScreenshotView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/16/26.
//

import SwiftUI

// MARK: - 참조 크기 및 미리 정의된 하이라이트

private let kReferenceWidth: CGFloat = 393
private let kReferenceHeight: CGFloat = 852

private func predefinedRects(for step: Int) -> [CGRect] {
    switch step {
    case 1:  // 이번 달 소비 카드
        return [CGRect(x: 40, y: 320, width: 313, height: 120)]
    case 2:  // 말풍선 (버블 + 꼬리 2개)
        return [
            CGRect(x: 80, y: 200, width: 200, height: 80),
            CGRect(x: 120, y: 278, width: 24, height: 16),
            CGRect(x: 140, y: 290, width: 16, height: 12)
        ]
    case 3:  // 소비 습관 카드
        return [CGRect(x: 40, y: 280, width: 313, height: 180)]
    case 4:  // 목표 스와이프 카드
        return [CGRect(x: 40, y: 300, width: 313, height: 100)]
    case 5:  // 날짜/캘린더
        return [CGRect(x: 40, y: 350, width: 313, height: 200)]
    case 6:  // + 버튼
        return [CGRect(x: 330, y: 60, width: 44, height: 44)]
    case 7:  // 거래 행
        return [CGRect(x: 40, y: 280, width: 313, height: 72)]
    case 8:  // 목표 목록 + 버튼
        return [CGRect(x: 40, y: 120, width: 313, height: 400)]
    case 9:  // 토글들
        return [CGRect(x: 40, y: 200, width: 313, height: 250)]
    case 10: // 목표 추가 버튼
        return [CGRect(x: 40, y: 550, width: 313, height: 52)]
    case 11: // 월간 리포트 카드
        return [CGRect(x: 40, y: 180, width: 313, height: 180)]
    case 12: // 고정지출 카드
        return [CGRect(x: 40, y: 200, width: 313, height: 200)]
    default:
        return [CGRect(x: 96.5, y: 376, width: 200, height: 100)]
    }
}

private func predefinedFrames(for step: Int, in size: CGSize) -> [Int: [CGRect]] {
    let scaleX = size.width / kReferenceWidth
    let scaleY = size.height / kReferenceHeight
    let scaled = predefinedRects(for: step).map { r in
        CGRect(
            x: r.minX * scaleX,
            y: r.minY * scaleY,
            width: r.width * scaleX,
            height: r.height * scaleY
        )
    }
    return [step: scaled]
}

// MARK: - 스크린샷 튜토리얼 뷰

struct TutorialScreenshotView: View {
    @EnvironmentObject var store: OnboardingStore

    var body: some View {
        let step = store.currentStep
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                screenshotImage(step: step, size: size)
                OnboardingOverlayView(
                    store: store,
                    frames: predefinedFrames(for: step, in: size),
                    screenSize: size
                )
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func screenshotImage(step: Int, size: CGSize) -> some View {
        let name = "TutorialStep\(step)"
        if let img = UIImage(named: name) {
            Image(uiImage: img)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipped()
        } else {
            Color.gray.opacity(0.9)
                .overlay(
                    Text("TutorialStep\(step)")
                        .foregroundColor(.white)
                        .font(.caption)
                )
        }
    }
}

#Preview {
    TutorialScreenshotView()
        .environmentObject(OnboardingStore())
}
