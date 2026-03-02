//
//  OnboardingOverlayView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/16/26.
//

import SwiftUI

// MARK: - Frame 수집 (PreferenceKey)

struct OnboardingFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: [CGRect]] { [:] }
    static func reduce(value: inout [Int: [CGRect]], nextValue: () -> [Int: [CGRect]]) {
        for (k, rects) in nextValue() {
            value[k] = (value[k] ?? []) + rects
        }
    }
}

struct OnboardingFrameModifier: ViewModifier {
    let stepId: Int
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { g in
                Color.clear.preference(
                    key: OnboardingFramePreferenceKey.self,
                    value: [stepId: [g.frame(in: .global)]]
                )
            }
        )
    }
}

extension View {
    func onboardingFrame(stepId: Int) -> some View {
        modifier(OnboardingFrameModifier(stepId: stepId))
    }
}

// MARK: - 레이아웃 상수 (OnboardingLayoutLock)

private enum OnboardingLayoutLock {
    static let referenceScreenWidth: CGFloat = 393
    static let referenceScreenHeight: CGFloat = 852

    static func scaleX(_ size: CGSize) -> CGFloat { size.width / referenceScreenWidth }
    static func scaleY(_ size: CGSize) -> CGFloat { size.height / referenceScreenHeight }

    static func uniformScaleAndOffset(overlaySize: CGSize) -> (scale: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
        let scale = min(overlaySize.width / referenceScreenWidth, overlaySize.height / referenceScreenHeight)
        let offsetX = (overlaySize.width - referenceScreenWidth * scale) / 2
        let offsetY = (overlaySize.height - referenceScreenHeight * scale) / 2
        return (scale, offsetX, offsetY)
    }

    static let topBarHeight: CGFloat = 40
    static let bottomRowHeight: CGFloat = 88
    static func contentOffsetY(overlayHeight: CGFloat) -> CGFloat {
        let scale = overlayHeight / referenceScreenHeight
        let raw = CGFloat(58) * scale
        return min(max(raw, 40), 76)
    }

    static let safeInsetH: CGFloat = 20
    static let safeInsetTopExtra: CGFloat = 20
    static let safeInsetBottomExtra: CGFloat = 20
    static let tooltipSideMargin: CGFloat = 48
    static let tooltipBottomInsetAboveTabBar: CGFloat = 56
    static let tooltipGapFromHighlight: CGFloat = 24
    static let tooltipMinClearance: CGFloat = 12
    static let tooltipBlockWidth: CGFloat = 260
    static let tooltipBlockHeight: CGFloat = 58
    static let maxArrowLength: CGFloat = 44
    static let unifiedArrowTipClearance: CGFloat = 22
    static let arrowHeadSize: CGFloat = 6
    static let arrowStrokeWidth: CGFloat = 1.8
    static let curveBulge: CGFloat = 10

    static let step2Raise: CGFloat = 156
    static let step2CyFloorOffset: CGFloat = -10
    static let step2CxShift: CGFloat = 22
    static let step2VerticalLength: CGFloat = 18
    static let step2ArrowUp: CGFloat = 12
    static let step2ArrowLeftOffset: CGFloat = -40
    static let step2ArrowEndXOffset: CGFloat = -6
    static let step2CornerRadius: CGFloat = 8
    static let step2HeadSize: CGFloat = 5

    static let step6CxOffsetFromCenter: CGFloat = 78
    static let step6CyOffsetFromTopBar: CGFloat = 35
    static let step6HLen: CGFloat = 26
    static let step6RightShift: CGFloat = 44
    static let step6ArrowUp: CGFloat = 12
    static let step6FallbackXFromRight: CGFloat = 42
    static let step6FallbackYFromTop: CGFloat = 44
    static let step6FallbackSize: CGFloat = 44
    static let step6Padding: CGFloat = 16
    static let step6HighlightOffsetX: CGFloat = 0
    static let step6HighlightOffsetY: CGFloat = 0
    static let step6ArrowTipGapFromHighlight: CGFloat = 10
    static let step6ArrowGapFromTextEdge: CGFloat = 4
    static let step6ArrowMinHorizontal: CGFloat = 24
    static let step6CutoutDiameter: CGFloat = 44
    static let step6RingDiameter: CGFloat = 50
    static let step6RingStrokeOpacity: CGFloat = 0.85
    static let step6RingFillOpacity: CGFloat = 0.28
    static let step6RingLineWidth: CGFloat = 2.5
    static let step6CornerRadius: CGFloat = 12
    static let step6HeadSize: CGFloat = 5
    static let step6ArrowOffsetX: CGFloat = 30

    static let step1_3_4_pushDownRefY: CGFloat = 68
    static let stepPushDownRefY: CGFloat = 52
    static let step2TextPushDownRefY: CGFloat = 16
    static let step2ArrowPushDownRefY: CGFloat = 58
    static let step2HighlightOffsetY: CGFloat = 0
    static let step6PushDownRefY: CGFloat = 18
    static let step9PushDownRefY: CGFloat = 67
    static let step10PushDownRefY: CGFloat = 62
    static let step7PushDownRefY: CGFloat = 66
    static let step11PushDownRefY: CGFloat = 66
    static let step7HighlightOffsetY: CGFloat = -6
    static let step11HighlightOffsetY: CGFloat = -6

    static let step9ArrowEndOffsetX: CGFloat = -20
    static let step2EffectiveBulge: CGFloat = 5

    static let tooltipBlockPullUp: CGFloat = 30

    static func forceExtraGapAbove(stepId: Int) -> CGFloat {
        switch stepId {
        case 1: return 58
        case 3: return 48
        case 4: return 84 + tooltipBlockPullUp
        case 5: return 58 + tooltipBlockPullUp
        case 7: return 48 + tooltipBlockPullUp
        case 10: return 78 + tooltipBlockPullUp
        case 8, 9, 11, 12: return 58 + tooltipBlockPullUp
        default: return 0
        }
    }

    static func arrowEndOffsetAbove(stepId: Int) -> CGFloat {
        switch stepId {
        case 1: return 54
        case 2: return 22
        case 3: return 28
        case 4: return 68 + tooltipBlockPullUp
        case 5: return 54 + tooltipBlockPullUp
        case 7: return 44 + tooltipBlockPullUp
        case 9: return -10 + tooltipBlockPullUp
        case 10: return 70 + tooltipBlockPullUp
        case 11, 12: return 52 + tooltipBlockPullUp
        default: return 0
        }
    }

    static func arrowEndOffsetBelow(stepId: Int) -> CGFloat {
        stepId == 8 ? 56 + tooltipBlockPullUp : 0
    }

    static func blockPullUpBelow(stepId: Int) -> CGFloat {
        stepId == 8 ? 44 + tooltipBlockPullUp : 0
    }

    static let step1Inset: CGFloat = 10
    static let step3Inset: CGFloat = 8
    static let step4Padding: CGFloat = 14
    static let step7PaddingH: CGFloat = 12
    static let step7PaddingT: CGFloat = 10
    static let step7PaddingB: CGFloat = 16
    static let step9Padding: CGFloat = 12
    static let step10Padding: CGFloat = 12
    static let step12Padding: CGFloat = 16  // 고정지출 카드 하이라이트 갭
    static let step2SpeechBubbleCornerRadius: CGFloat = 22
}

// MARK: - Dim + 컴포넌트 영역만 구멍

// MARK: - 하이라이트 주변 플로팅 툴팁 (작은 화살표 + 설명)

private let tooltipGapFromHighlight: CGFloat = OnboardingLayoutLock.tooltipGapFromHighlight
private let tooltipMinClearance: CGFloat = OnboardingLayoutLock.tooltipMinClearance
private let tooltipBlockWidth: CGFloat = OnboardingLayoutLock.tooltipBlockWidth
private let tooltipBlockHeight: CGFloat = OnboardingLayoutLock.tooltipBlockHeight
private let maxArrowLength: CGFloat = OnboardingLayoutLock.maxArrowLength
private let arrowHeadSize: CGFloat = OnboardingLayoutLock.arrowHeadSize
private let arrowStrokeWidth: CGFloat = OnboardingLayoutLock.arrowStrokeWidth
private let curveBulge: CGFloat = OnboardingLayoutLock.curveBulge

// MARK: - 2번 화살표

private struct Step2ArrowShape: Shape {
    var start: CGPoint
    var end: CGPoint
    var headSize: CGFloat = arrowHeadSize
    var cornerRadius: CGFloat = 10

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = cornerRadius
        let cornerY = end.y
        let cornerX = start.x
        let vertBottomY = cornerY - r
        if start.y >= vertBottomY { return p }
        p.move(to: start)
        p.addLine(to: CGPoint(x: cornerX, y: vertBottomY))
        p.addQuadCurve(to: CGPoint(x: cornerX + r, y: cornerY), control: CGPoint(x: cornerX, y: cornerY))
        p.addLine(to: CGPoint(x: end.x - headSize * 1.2, y: cornerY))
        p.addLine(to: end)
        let angle: CGFloat = 0
        let spread: CGFloat = .pi / 5
        let t1 = CGPoint(x: end.x - headSize * cos(angle - spread), y: end.y - headSize * sin(angle - spread))
        let t2 = CGPoint(x: end.x - headSize * cos(angle + spread), y: end.y - headSize * sin(angle + spread))
        p.move(to: end)
        p.addLine(to: t1)
        p.move(to: end)
        p.addLine(to: t2)
        return p
    }
}

// MARK: - 6번 화살표

private struct Step6ArrowShape: Shape {
    var start: CGPoint
    var end: CGPoint
    var headSize: CGFloat = 5
    var cornerRadius: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let vertLen = abs(start.y - end.y)
        let r = min(cornerRadius, max(6, vertLen * 0.35))
        let bendX = end.x
        let bendY = start.y

        p.move(to: start)
        p.addLine(to: CGPoint(x: bendX - r, y: bendY))

        p.addQuadCurve(
            to: CGPoint(x: bendX, y: bendY - r),
            control: CGPoint(x: bendX, y: bendY)
        )

        let stopY = end.y + headSize
        if bendY - r > stopY {
            p.addLine(to: CGPoint(x: bendX, y: stopY))
        }
        p.addLine(to: end)

        let angle: CGFloat = -.pi / 2
        let spread: CGFloat = .pi / 5
        let t1 = CGPoint(x: end.x - headSize * cos(angle - spread), y: end.y - headSize * sin(angle - spread))
        let t2 = CGPoint(x: end.x - headSize * cos(angle + spread), y: end.y - headSize * sin(angle + spread))
        p.move(to: end)
        p.addLine(to: t1)
        p.move(to: end)
        p.addLine(to: t2)
        return p
    }
}

// MARK: - 곡선 화살표 (일반 툴팁)

private struct CurvedArrowShape: Shape {
    var start: CGPoint
    var end: CGPoint
    var headSize: CGFloat = arrowHeadSize
    var bulge: CGFloat = curveBulge
    var headAngleOffset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let dx = end.x - start.x
        let dy = end.y - start.y
        let dist = sqrt(dx * dx + dy * dy)
        if dist < 2 { return p }
        let ux = dx / dist
        let uy = dy / dist
        let curveEnd = CGPoint(x: end.x - ux * headSize * 1.2, y: end.y - uy * headSize * 1.2)
        let distToCurve = hypot(curveEnd.x - start.x, curveEnd.y - start.y)
        if distToCurve < 1 { return p }
        let midX = (start.x + curveEnd.x) / 2
        let midY = (start.y + curveEnd.y) / 2
        let perpX = -uy
        let perpY = ux
        let ctrl = CGPoint(x: midX + perpX * bulge, y: midY + perpY * bulge)
        p.move(to: start)
        p.addQuadCurve(to: curveEnd, control: ctrl)
        p.addLine(to: end)
        let angle = atan2(dy, dx) + headAngleOffset
        let spread: CGFloat = .pi / 5
        let t1 = CGPoint(x: end.x - headSize * cos(angle - spread), y: end.y - headSize * sin(angle - spread))
        let t2 = CGPoint(x: end.x - headSize * cos(angle + spread), y: end.y - headSize * sin(angle + spread))
        p.move(to: end)
        p.addLine(to: t1)
        p.move(to: end)
        p.addLine(to: t2)
        return p
    }
}

// MARK: - 툴팁 위치/화살표 계산 헬퍼

private func expandedHighlight(_ r: CGRect, gap: CGFloat) -> CGRect {
    r.insetBy(dx: -gap, dy: -gap)
}

private func textRect(cx: CGFloat, cy: CGFloat, halfW: CGFloat, halfH: CGFloat) -> CGRect {
    CGRect(x: cx - halfW, y: cy - halfH, width: halfW * 2, height: halfH * 2)
}

// MARK: - 툴팁 레이아웃 (Zone + compute)

private struct TooltipLayout {
    let zone: Zone
    let textCenterX: CGFloat
    let textCenterY: CGFloat
    let arrowStart: CGPoint
    let arrowEnd: CGPoint

    enum Zone { case above, below, left, right }

    static func safeArrowLength(start: CGPoint, target: CGPoint, highlight: CGRect, margin: CGFloat) -> CGFloat {
        let dx = target.x - start.x
        let dy = target.y - start.y
        let d = sqrt(dx * dx + dy * dy)
        if d < 0.5 { return 0 }
        let ux = dx / d
        let uy = dy / d
        let e = expandedHighlight(highlight, gap: margin)
        var tMin: CGFloat = d + 1
        if ux != 0 {
            let tL = (e.minX - start.x) / ux
            let tR = (e.maxX - start.x) / ux
            if tL > 0, start.y + tL * uy >= e.minY, start.y + tL * uy <= e.maxY { tMin = min(tMin, tL) }
            if tR > 0, start.y + tR * uy >= e.minY, start.y + tR * uy <= e.maxY { tMin = min(tMin, tR) }
        }
        if uy != 0 {
            let tT = (e.minY - start.y) / uy
            let tB = (e.maxY - start.y) / uy
            if tT > 0, start.x + tT * ux >= e.minX, start.x + tT * ux <= e.maxX { tMin = min(tMin, tT) }
            if tB > 0, start.x + tB * ux >= e.minX, start.x + tB * ux <= e.maxX { tMin = min(tMin, tB) }
        }
        let safe = max(0, tMin - 2)
        return min(d, safe)
    }

    static func shortArrowEnd(start: CGPoint, target: CGPoint, maxLen: CGFloat) -> CGPoint {
        let dx = target.x - start.x
        let dy = target.y - start.y
        let d = sqrt(dx * dx + dy * dy)
        if d <= 0.5 { return start }
        let len = min(maxLen, d)
        let ux = dx / d
        let uy = dy / d
        return CGPoint(x: start.x + ux * len, y: start.y + uy * len)
    }

    static func compute(highlight: CGRect, overlaySize: CGSize, topBarH: CGFloat, bottomRowH: CGFloat, textWidth: CGFloat, textHeight: CGFloat, gap: CGFloat, preferredZones: [Zone]? = nil, forceExtraGapAbove: CGFloat = 0, arrowEndOffsetAbove: CGFloat = 0, arrowEndOffsetBelow: CGFloat = 0, blockPullUpBelow: CGFloat = 0, maxArrowLengthOverride: CGFloat? = nil) -> TooltipLayout {
        let sx = OnboardingLayoutLock.scaleX(overlaySize)
        let sy = OnboardingLayoutLock.scaleY(overlaySize)
        let cap = maxArrowLengthOverride ?? (maxArrowLength * min(sx, sy))
        let margin = gap + tooltipMinClearance * min(sx, sy)
        let safeTop = topBarH + OnboardingLayoutLock.safeInsetTopExtra * sy
        let safeBottom = overlaySize.height - bottomRowH - OnboardingLayoutLock.safeInsetBottomExtra * sy
        let safeLeft = OnboardingLayoutLock.safeInsetH * sx
        let safeRight = overlaySize.width - OnboardingLayoutLock.safeInsetH * sx
        let needH = textHeight + gap
        let needW = textWidth + gap
        let spaceAbove = highlight.minY - safeTop
        let spaceBelow = safeBottom - highlight.maxY
        let spaceLeft = highlight.minX - safeLeft
        let spaceRight = safeRight - highlight.maxX

        let halfW = textWidth / 2
        let halfH = textHeight / 2
        let exp = expandedHighlight(highlight, gap: gap + tooltipMinClearance)

        func clampX(_ x: CGFloat) -> CGFloat { min(max(x, safeLeft + halfW), safeRight - halfW) }
        func clampY(_ y: CGFloat) -> CGFloat { min(max(y, safeTop + halfH), safeBottom - halfH) }

        func ensureTextOutside(cx: CGFloat, cy: CGFloat, zone: Zone) -> (CGFloat, CGFloat) {
            var x = cx, y = cy
            let clearance = gap + tooltipMinClearance
            let tr = textRect(cx: x, cy: y, halfW: halfW, halfH: halfH)
            if !tr.intersects(exp) { return (x, y) }
            switch zone {
            case .above: y = min(y, highlight.minY - clearance - halfH)
            case .below: y = max(y, highlight.maxY + clearance + halfH)
            case .left:  x = min(x, highlight.minX - clearance - halfW)
            case .right: x = max(x, highlight.maxX + clearance + halfW)
            }
            return (clampX(x), clampY(y))
        }

        if let pref = preferredZones {
            for z in pref {
                switch z {
                case .below where spaceBelow >= needH:
                    let baseCy = highlight.maxY + gap + halfH - blockPullUpBelow
                    var cy = max(safeTop + halfH, min(safeBottom - halfH, baseCy))
                    var cx = clampX(highlight.midX)
                    (cx, cy) = ensureTextOutside(cx: cx, cy: cy, zone: .below)
                    cy = max(cy, baseCy + 2)
                    let aStart = CGPoint(x: cx, y: cy - halfH)
                    let target = CGPoint(x: highlight.midX, y: highlight.maxY + gap * 0.5 - arrowEndOffsetBelow)
                    let safeLen = safeArrowLength(start: aStart, target: target, highlight: highlight, margin: margin)
                    let end = shortArrowEnd(start: aStart, target: target, maxLen: min(cap, safeLen))
                    return TooltipLayout(zone: .below, textCenterX: cx, textCenterY: cy, arrowStart: aStart, arrowEnd: end)
                case .left where spaceLeft >= needW:
                    var cx = min(highlight.minX - gap - halfW, max(safeLeft + halfW, highlight.minX - gap - halfW))
                    var cy = clampY(highlight.midY)
                    (cx, cy) = ensureTextOutside(cx: cx, cy: cy, zone: .left)
                    cx = min(cx, highlight.minX - gap - halfW - 2)
                    let aStart = CGPoint(x: cx + halfW, y: cy)
                    let target = CGPoint(x: highlight.minX - gap * 0.5, y: highlight.midY)
                    let safeLen = safeArrowLength(start: aStart, target: target, highlight: highlight, margin: margin)
                    let end = shortArrowEnd(start: aStart, target: target, maxLen: min(cap, safeLen))
                    return TooltipLayout(zone: .left, textCenterX: cx, textCenterY: cy, arrowStart: aStart, arrowEnd: end)
                case .above where spaceAbove >= needH:
                    let extra = forceExtraGapAbove
                    var cy = min(highlight.minY - gap - halfH - extra, max(safeTop + halfH, highlight.minY - gap - halfH - extra))
                    var cx = clampX(highlight.midX)
                    (cx, cy) = ensureTextOutside(cx: cx, cy: cy, zone: .above)
                    cy = min(cy, highlight.minY - gap - halfH - max(2, extra))
                    let aStart = CGPoint(x: cx, y: cy + halfH)
                    let target = CGPoint(x: highlight.midX, y: highlight.minY - gap * 0.5 - arrowEndOffsetAbove)
                    let safeLen = safeArrowLength(start: aStart, target: target, highlight: highlight, margin: margin)
                    let end = shortArrowEnd(start: aStart, target: target, maxLen: min(cap, safeLen))
                    return TooltipLayout(zone: .above, textCenterX: cx, textCenterY: cy, arrowStart: aStart, arrowEnd: end)
                case .right where spaceRight >= needW:
                    var cx = max(highlight.maxX + gap + halfW, min(safeRight - halfW, highlight.maxX + gap + halfW))
                    var cy = clampY(highlight.midY)
                    (cx, cy) = ensureTextOutside(cx: cx, cy: cy, zone: .right)
                    cx = max(cx, highlight.maxX + gap + halfW + 2)
                    let aStart = CGPoint(x: cx - halfW, y: cy)
                    let target = CGPoint(x: highlight.maxX + gap * 0.5, y: highlight.midY)
                    let safeLen = safeArrowLength(start: aStart, target: target, highlight: highlight, margin: margin)
                    let end = shortArrowEnd(start: aStart, target: target, maxLen: min(cap, safeLen))
                    return TooltipLayout(zone: .right, textCenterX: cx, textCenterY: cy, arrowStart: aStart, arrowEnd: end)
                default: continue
                }
            }
        }

        if spaceAbove >= needH && spaceAbove >= spaceBelow {
            let extra = forceExtraGapAbove
            var cy = min(highlight.minY - gap - halfH - extra, max(safeTop + halfH, highlight.minY - gap - halfH - extra))
            var cx = clampX(highlight.midX)
            (cx, cy) = ensureTextOutside(cx: cx, cy: cy, zone: .above)
            cy = min(cy, highlight.minY - gap - halfH - max(2, extra))
            let aStart = CGPoint(x: cx, y: cy + halfH)
            let target = CGPoint(x: highlight.midX, y: highlight.minY - gap * 0.5 - arrowEndOffsetAbove)
            let safeLen = safeArrowLength(start: aStart, target: target, highlight: highlight, margin: margin)
            let end = shortArrowEnd(start: aStart, target: target, maxLen: min(cap, safeLen))
            return TooltipLayout(zone: .above, textCenterX: cx, textCenterY: cy, arrowStart: aStart, arrowEnd: end)
        }
        if spaceBelow >= needH {
            let baseCy = highlight.maxY + gap + halfH - blockPullUpBelow
            var cy = max(safeTop + halfH, min(safeBottom - halfH, baseCy))
            var cx = clampX(highlight.midX)
            (cx, cy) = ensureTextOutside(cx: cx, cy: cy, zone: .below)
            cy = max(cy, baseCy + 2)
            let aStart = CGPoint(x: cx, y: cy - halfH)
            let target = CGPoint(x: highlight.midX, y: highlight.maxY + gap * 0.5 - arrowEndOffsetBelow)
            let safeLen = safeArrowLength(start: aStart, target: target, highlight: highlight, margin: margin)
            let end = shortArrowEnd(start: aStart, target: target, maxLen: min(cap, safeLen))
            return TooltipLayout(zone: .below, textCenterX: cx, textCenterY: cy, arrowStart: aStart, arrowEnd: end)
        }
        if spaceLeft >= needW && spaceLeft >= spaceRight {
            var cx = min(highlight.minX - gap - halfW, max(safeLeft + halfW, highlight.minX - gap - halfW))
            var cy = clampY(highlight.midY)
            (cx, cy) = ensureTextOutside(cx: cx, cy: cy, zone: .left)
            cx = min(cx, highlight.minX - gap - halfW - 2)
            let aStart = CGPoint(x: cx + halfW, y: cy)
            let target = CGPoint(x: highlight.minX - gap * 0.5, y: highlight.midY)
            let safeLen = safeArrowLength(start: aStart, target: target, highlight: highlight, margin: margin)
            let end = shortArrowEnd(start: aStart, target: target, maxLen: min(cap, safeLen))
            return TooltipLayout(zone: .left, textCenterX: cx, textCenterY: cy, arrowStart: aStart, arrowEnd: end)
        }
        var cx = max(highlight.maxX + gap + halfW, min(safeRight - halfW, highlight.maxX + gap + halfW))
        var cy = clampY(highlight.midY)
        (cx, cy) = ensureTextOutside(cx: cx, cy: cy, zone: .right)
        cx = max(cx, highlight.maxX + gap + halfW + 2)
        let aStart = CGPoint(x: cx - halfW, y: cy)
        let target = CGPoint(x: highlight.maxX + gap * 0.5, y: highlight.midY)
        let safeLen = safeArrowLength(start: aStart, target: target, highlight: highlight, margin: margin)
        let end = shortArrowEnd(start: aStart, target: target, maxLen: min(cap, safeLen))
        return TooltipLayout(zone: .right, textCenterX: cx, textCenterY: cy, arrowStart: aStart, arrowEnd: end)
    }
}

// MARK: - 플로팅 툴팁 뷰 (메시지 + 화살표 + 좌우 탭)

private struct FloatingTooltipView: View {
    let message: String
    let highlightRectInLocal: CGRect
    let overlaySize: CGSize
    let layoutScale: CGFloat
    let layoutOffset: CGPoint
    let stepId: Int
    let isFirstStep: Bool
    let isLastStep: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void

    private var refPushDownY: CGFloat {
        switch stepId {
        case 1, 3, 4: return OnboardingLayoutLock.step1_3_4_pushDownRefY
        case 2: return OnboardingLayoutLock.stepPushDownRefY
        case 6: return OnboardingLayoutLock.step6PushDownRefY
        case 7: return OnboardingLayoutLock.step7PushDownRefY
        case 9: return OnboardingLayoutLock.step9PushDownRefY
        case 10: return OnboardingLayoutLock.step10PushDownRefY
        case 11: return OnboardingLayoutLock.step11PushDownRefY
        case 5, 8, 12: return OnboardingLayoutLock.stepPushDownRefY
        default: return 0
        }
    }
    private var refTextPushDownY: CGFloat {
        switch stepId {
        case 2: return OnboardingLayoutLock.step2TextPushDownRefY
        default: return refPushDownY
        }
    }
    private var refArrowPushDownY: CGFloat {
        switch stepId {
        case 2: return OnboardingLayoutLock.step2ArrowPushDownRefY
        default: return refPushDownY
        }
    }
    private func toScreenY(_ y: CGFloat) -> CGFloat { (y + refTextPushDownY) * layoutScale + layoutOffset.y }
    private func toScreenArrow(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x * layoutScale + layoutOffset.x, y: (p.y + refArrowPushDownY) * layoutScale + layoutOffset.y)
    }

    private var topBarHeight: CGFloat { OnboardingLayoutLock.topBarHeight }
    private var bottomRowHeight: CGFloat { OnboardingLayoutLock.bottomRowHeight }

    private var preferredZones: [TooltipLayout.Zone]? {
        switch stepId {
        case 1, 3, 4, 5, 9, 10, 11, 12: return [.above]
        case 2: return [.left]
        case 6: return [.right, .below]
        case 8: return [.below]
        default: return nil
        }
    }

    private var forceExtraGapAbove: CGFloat { OnboardingLayoutLock.forceExtraGapAbove(stepId: stepId) }
    private var arrowEndOffsetAbove: CGFloat { OnboardingLayoutLock.arrowEndOffsetAbove(stepId: stepId) }
    private var arrowEndOffsetX: CGFloat { stepId == 9 ? OnboardingLayoutLock.step9ArrowEndOffsetX : 0 }
    private var effectiveBulge: CGFloat { stepId == 2 ? OnboardingLayoutLock.step2EffectiveBulge : curveBulge }

    private var arrowBulge: CGFloat {
        curveBulge
    }

    private var layout: TooltipLayout {
        let sx = OnboardingLayoutLock.scaleX(overlaySize)
        let sy = OnboardingLayoutLock.scaleY(overlaySize)

        if stepId == 2 {
            let tw = min(tooltipBlockWidth * sx, overlaySize.width - OnboardingLayoutLock.tooltipSideMargin * sx)
            let halfW = tw / 2
            let halfH = (tooltipBlockHeight * sy) / 2
            let gap = tooltipGapFromHighlight * min(sx, sy)
            let safeLeft = OnboardingLayoutLock.safeInsetH * sx
            let targetTopY = highlightRectInLocal.minY
            let targetLeftX = highlightRectInLocal.minX
            let raise = OnboardingLayoutLock.step2Raise * sy
            let cyFloor = topBarHeight * sy + halfH + OnboardingLayoutLock.step2CyFloorOffset * sy
            let cy = max(cyFloor, min(targetTopY - gap - halfH - raise, overlaySize.height - bottomRowHeight * sy - halfH - OnboardingLayoutLock.safeInsetBottomExtra * sy))
            let cxBase = max(safeLeft + halfW, min(targetLeftX - gap - halfW, overlaySize.width - halfW - safeLeft))
            let cx = min(cxBase + OnboardingLayoutLock.step2CxShift * sx, overlaySize.width - halfW - safeLeft)
            let verticalLength = OnboardingLayoutLock.step2VerticalLength * sy
            let arrowUp = OnboardingLayoutLock.step2ArrowUp * sy
            let arrowStart = CGPoint(x: targetLeftX + OnboardingLayoutLock.step2ArrowLeftOffset * sx, y: targetTopY - verticalLength - 18 * sy - arrowUp)
            let cornerY = arrowStart.y + verticalLength
            let arrowEnd = CGPoint(x: targetLeftX - gap * 0.5 + OnboardingLayoutLock.step2ArrowEndXOffset * sx, y: cornerY)
            return TooltipLayout(zone: .left, textCenterX: cx, textCenterY: cy, arrowStart: arrowStart, arrowEnd: arrowEnd)
        }
        if stepId == 6 {
            let textW = min(OnboardingLayoutLock.tooltipBlockWidth * sx, overlaySize.width - OnboardingLayoutLock.tooltipSideMargin * sx)
            let halfW = textW / 2
            let cx = overlaySize.width / 2 + OnboardingLayoutLock.step6CxOffsetFromCenter * sx
            let cy = topBarHeight * sy + (tooltipBlockHeight * sy) / 2 + OnboardingLayoutLock.step6CyOffsetFromTopBar * sy
            let fallbackW = OnboardingLayoutLock.step6FallbackSize * sx
            let fallbackH = OnboardingLayoutLock.step6FallbackSize * sy
            let base = highlightRectInLocal.width >= 20 && highlightRectInLocal.height >= 20
                ? highlightRectInLocal
                : CGRect(x: overlaySize.width - OnboardingLayoutLock.step6FallbackXFromRight * sx - fallbackW, y: topBarHeight * sy + OnboardingLayoutLock.step6FallbackYFromTop * sy, width: fallbackW, height: fallbackH)
            let rect = base.offsetBy(dx: OnboardingLayoutLock.step6HighlightOffsetX * sx, dy: OnboardingLayoutLock.step6HighlightOffsetY * sy)
            let ringD = OnboardingLayoutLock.step6RingDiameter * min(sx, sy)
            let circleTop = rect.midY - ringD / 2
            let tipX = rect.midX
            let tipY = circleTop - OnboardingLayoutLock.step6ArrowTipGapFromHighlight * sy
            let offsetX = OnboardingLayoutLock.step6ArrowOffsetX * sx
            let arrowEnd = CGPoint(x: tipX + offsetX, y: tipY)
            let textRightEdge = cx + halfW
            let startX = min(textRightEdge + OnboardingLayoutLock.step6ArrowGapFromTextEdge * sx, tipX - OnboardingLayoutLock.step6ArrowMinHorizontal * sx)
            let arrowStart = CGPoint(x: startX + offsetX, y: cy)
            return TooltipLayout(zone: .above, textCenterX: cx, textCenterY: cy, arrowStart: arrowStart, arrowEnd: arrowEnd)
        }
        return TooltipLayout.compute(
            highlight: highlightRectInLocal,
            overlaySize: overlaySize,
            topBarH: topBarHeight * sy,
            bottomRowH: bottomRowHeight * sy,
            textWidth: min(OnboardingLayoutLock.tooltipBlockWidth * sx, overlaySize.width - OnboardingLayoutLock.tooltipSideMargin * sx),
            textHeight: tooltipBlockHeight * sy,
            gap: tooltipGapFromHighlight * min(sx, sy),
            preferredZones: preferredZones,
            forceExtraGapAbove: forceExtraGapAbove * sy,
            arrowEndOffsetAbove: arrowEndOffsetAbove * sy,
            arrowEndOffsetBelow: OnboardingLayoutLock.arrowEndOffsetBelow(stepId: stepId) * sy,
            blockPullUpBelow: OnboardingLayoutLock.blockPullUpBelow(stepId: stepId) * sy,
            maxArrowLengthOverride: nil
        )
    }

    var body: some View {
        GeometryReader { geo in
            let sizeValid = overlaySize.width >= 20 && overlaySize.height >= 20
            let highlightValid = (highlightRectInLocal.width >= 20 && highlightRectInLocal.height >= 20) || stepId == 6
            let lo = layout
            let end = CGPoint(x: lo.arrowEnd.x + arrowEndOffsetX, y: lo.arrowEnd.y)
            let drawStartScreen = toScreenArrow(lo.arrowStart)
            let drawEndScreen = toScreenArrow(end)
            let textYScreen = toScreenY(lo.textCenterY)
            let textCenterXScreen = lo.textCenterX * layoutScale + layoutOffset.x
            let tooltipW = OnboardingLayoutLock.tooltipBlockWidth * layoutScale
            let tooltipH = OnboardingLayoutLock.tooltipBlockHeight * layoutScale
            ZStack(alignment: .topLeading) {
                if sizeValid && highlightValid {
                    if stepId == 2 {
                        Step2ArrowShape(start: drawStartScreen, end: drawEndScreen, headSize: OnboardingLayoutLock.step2HeadSize * layoutScale, cornerRadius: OnboardingLayoutLock.step2CornerRadius * layoutScale)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: arrowStrokeWidth, lineCap: .round, lineJoin: .round))
                    } else if stepId == 6 {
                        Step6ArrowShape(start: drawStartScreen, end: drawEndScreen, headSize: OnboardingLayoutLock.step6HeadSize * layoutScale, cornerRadius: OnboardingLayoutLock.step6CornerRadius * layoutScale)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: arrowStrokeWidth, lineCap: .round, lineJoin: .round))
                    } else {
                        CurvedArrowShape(start: drawStartScreen, end: drawEndScreen, headSize: arrowHeadSize * layoutScale, bulge: effectiveBulge * layoutScale, headAngleOffset: 0)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: arrowStrokeWidth, lineCap: .round, lineJoin: .round))
                    }
                    messageText
                        .frame(width: max(1, tooltipW), height: max(1, tooltipH))
                        .position(x: textCenterXScreen, y: textYScreen)
                }
            }
            .frame(width: max(1, geo.size.width), height: max(1, geo.size.height))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { if !isFirstStep { onPrevious() } }
                    .frame(maxWidth: .infinity)
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { onNext() }
                    .frame(maxWidth: .infinity)
            }
        )
        .overlay(alignment: .bottom) {
            Text("← 이전 | 다음 →")
                .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 108)
                .padding(.horizontal)
                .allowsHitTesting(false)
        }
    }

    private var messageText: some View {
        Text(message)
            .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .lineLimit(4)
    }
}

// MARK: - Step 6 원형 구멍 / 히트테스트

private struct OverlayHitTestShape: Shape {
    var holeCenter: CGPoint?
    var holeRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRect(rect)
        if let c = holeCenter {
            p.addEllipse(in: CGRect(x: c.x - holeRadius, y: c.y - holeRadius, width: holeRadius * 2, height: holeRadius * 2))
        }
        return p
    }
}

// MARK: - 메인 오버레이 뷰 (OnboardingOverlayView)

struct OnboardingOverlayView: View {
    @ObservedObject var store: OnboardingStore
    let frames: [Int: [CGRect]]
    let screenSize: CGSize

    private func unifiedRect(for step: Int) -> CGRect {
        guard let rects = frames[step], !rects.isEmpty else { return .zero }
        return rects.reduce(rects[0]) { $0.union($1) }
    }

    var body: some View {
        let step = store.currentStep
        let frame = unifiedRect(for: step)
        let step2Rects = step == 2 ? (frames[2] ?? []) : nil
        let config = store.config(for: step)
        let tooltipTargetFrame: CGRect = {
            if step == 2, let first = step2Rects?.first { return first }
            return frame
        }()

        GeometryReader { geo in
            let overlayOrigin = geo.frame(in: .global).origin
            let tooltipTargetLocal = CGRect(
                x: tooltipTargetFrame.minX - overlayOrigin.x,
                y: tooltipTargetFrame.minY - overlayOrigin.y,
                width: max(1, tooltipTargetFrame.width),
                height: max(1, tooltipTargetFrame.height)
            )
            let (layoutScale, offsetX, offsetY) = OnboardingLayoutLock.uniformScaleAndOffset(overlaySize: geo.size)
            let refHighlight = CGRect(
                x: (tooltipTargetLocal.minX - offsetX) / layoutScale,
                y: (tooltipTargetLocal.minY - offsetY) / layoutScale,
                width: tooltipTargetLocal.width / layoutScale,
                height: tooltipTargetLocal.height / layoutScale
            )
            let refSize = CGSize(width: OnboardingLayoutLock.referenceScreenWidth, height: OnboardingLayoutLock.referenceScreenHeight)
            ZStack {
                dimLayer(highlightFrame: frame, step: step, step2Rects: step2Rects)
                FloatingTooltipView(
                    message: config?.message ?? "",
                    highlightRectInLocal: refHighlight,
                    overlaySize: refSize,
                    layoutScale: layoutScale,
                    layoutOffset: CGPoint(x: offsetX, y: offsetY),
                    stepId: step,
                    isFirstStep: step == 1,
                    isLastStep: step == 12,
                    onPrevious: {
                        withAnimation(.easeInOut(duration: 0.25)) { store.goBack() }
                    },
                    onNext: {
                        withAnimation(.easeInOut(duration: 0.25)) { store.advance() }
                    },
                    onSkip: {
                        withAnimation(.easeInOut(duration: 0.25)) { store.skip() }
                    }
                )
            }
            .contentShape(OverlayHitTestShape(holeCenter: nil, holeRadius: 0))
        }
        .ignoresSafeArea()
        .allowsHitTesting(true)
    }

    // MARK: - Dim 레이어 (구멍 유효성 + cutout 분기)

    private static func isHighlightValidForCutout(step: Int, highlightFrame: CGRect) -> Bool {
        if step == 6 { return false }
        guard (1...4).contains(step) else { return true }
        return highlightFrame.width >= 20 && highlightFrame.height >= 20
    }

    private func dimLayer(highlightFrame: CGRect, step: Int, step2Rects: [CGRect]?) -> some View {
        let drawCutout = Self.isHighlightValidForCutout(step: step, highlightFrame: highlightFrame)
        return GeometryReader { geo in
            let toLocal: (CGRect) -> CGRect = { r in
                CGRect(
                    x: r.minX - geo.frame(in: .global).minX,
                    y: r.minY - geo.frame(in: .global).minY,
                    width: max(1, r.width),
                    height: max(1, r.height)
                )
            }
            let raw = toLocal(highlightFrame)
            let s = min(OnboardingLayoutLock.scaleX(geo.size), OnboardingLayoutLock.scaleY(geo.size))
            let localRect: CGRect = {
                if step == 1 {
                    let i = OnboardingLayoutLock.step1Inset * s
                    return raw.insetBy(dx: i, dy: i)
                }
                if step == 3 {
                    let i = OnboardingLayoutLock.step3Inset * s
                    return raw.insetBy(dx: i, dy: i)
                }
                if step == 4 {
                    let p = OnboardingLayoutLock.step4Padding * s
                    return raw.insetBy(dx: -p, dy: -p)
                }
                if step == 6 {
                    let sx = OnboardingLayoutLock.scaleX(geo.size)
                    let sy = OnboardingLayoutLock.scaleY(geo.size)
                    let offsetX = OnboardingLayoutLock.step6HighlightOffsetX * sx
                    let offsetY = OnboardingLayoutLock.step6HighlightOffsetY * sy
                    let d = OnboardingLayoutLock.step6CutoutDiameter * min(sx, sy)
                    if raw.width >= 8, raw.height >= 8 {
                        let r = raw.offsetBy(dx: offsetX, dy: offsetY)
                        return CGRect(x: r.midX - d / 2, y: r.midY - d / 2, width: d, height: d)
                    }
                    let fw = OnboardingLayoutLock.step6FallbackSize * sx
                    let fh = OnboardingLayoutLock.step6FallbackSize * sy
                    let fallback = CGRect(
                        x: geo.size.width - OnboardingLayoutLock.step6FallbackXFromRight * sx - fw,
                        y: OnboardingLayoutLock.step6FallbackYFromTop * sy,
                        width: fw,
                        height: fh
                    )
                    let r = fallback.offsetBy(dx: offsetX, dy: offsetY)
                    return CGRect(x: r.midX - d / 2, y: r.midY - d / 2, width: d, height: d)
                }
                if step == 7 {
                    let ph = OnboardingLayoutLock.step7PaddingH * s
                    let pt = OnboardingLayoutLock.step7PaddingT * s
                    let pb = OnboardingLayoutLock.step7PaddingB * s
                    let r = raw.insetBy(dx: -ph, dy: 0)
                    let dy = OnboardingLayoutLock.step7HighlightOffsetY * s
                    return CGRect(x: r.minX, y: r.minY - pt + dy, width: r.width, height: r.height + pt + pb)
                }
                if step == 9 {
                    let p = OnboardingLayoutLock.step9Padding * s
                    return raw.insetBy(dx: -p, dy: -p)
                }
                if step == 10 {
                    let p = OnboardingLayoutLock.step10Padding * s
                    return raw.insetBy(dx: -p, dy: -p)
                }
                if step == 11 {
                    let p = OnboardingLayoutLock.step9Padding * s
                    let dy = OnboardingLayoutLock.step11HighlightOffsetY * s
                    return raw.insetBy(dx: -p, dy: -p).offsetBy(dx: 0, dy: dy)
                }
                if step == 12 {
                    let p = OnboardingLayoutLock.step12Padding * s
                    return raw.insetBy(dx: -p, dy: -p)
                }
                return raw
            }()
            ZStack {
                Color.black.opacity(0.80)
                if drawCutout {
                    if step == 2, let rects = step2Rects, rects.count >= 3 {
                        let dy = OnboardingLayoutLock.step2HighlightOffsetY
                        speechBubbleCutout(
                            bubbleLocal: toLocal(rects[0]).offsetBy(dx: 0, dy: dy),
                            tail1Local: toLocal(rects[1]).offsetBy(dx: 0, dy: dy),
                            tail2Local: toLocal(rects[2]).offsetBy(dx: 0, dy: dy)
                        )
                    } else if step == 6 {
                        circleCutout(localRect: localRect)
                    } else {
                        componentCutout(localRect: localRect, step: step)
                    }
                }
            }
            .compositingGroup()
            .contentShape(Rectangle())
        }
        .ignoresSafeArea()
    }

    // MARK: - Step 2 말풍선 구멍 (버블 + 꼬리 2개)

    private func speechBubbleCutout(bubbleLocal: CGRect, tail1Local: CGRect, tail2Local: CGRect) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: OnboardingLayoutLock.step2SpeechBubbleCornerRadius, style: .continuous)
                .foregroundStyle(Color.white)
                .frame(width: bubbleLocal.width, height: bubbleLocal.height)
                .position(x: bubbleLocal.midX, y: bubbleLocal.midY)
                .blendMode(.destinationOut)
            Ellipse()
                .foregroundStyle(Color.white)
                .frame(width: tail1Local.width, height: tail1Local.height)
                .position(x: tail1Local.midX, y: tail1Local.midY)
                .blendMode(.destinationOut)
            Ellipse()
                .foregroundStyle(Color.white)
                .frame(width: tail2Local.width, height: tail2Local.height)
                .position(x: tail2Local.midX, y: tail2Local.midY)
                .blendMode(.destinationOut)
        }
    }

    // MARK: - Step 6 원형 구멍

    private func circleCutout(localRect: CGRect) -> some View {
        let side = max(1, min(localRect.width, localRect.height))
        return Circle()
            .foregroundStyle(Color.white)
            .frame(width: side, height: side)
            .position(x: localRect.midX, y: localRect.midY)
            .blendMode(.destinationOut)
    }

    // MARK: - 일반 컴포넌트 구멍 (RoundedRectangle)

    @ViewBuilder
    private func componentCutout(localRect: CGRect, step: Int) -> some View {
        let corner = step == 2 ? OnboardingLayoutLock.step2SpeechBubbleCornerRadius : Theme.cardCorner
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .foregroundStyle(Color.white)
            .frame(width: localRect.width, height: localRect.height)
            .position(x: localRect.midX, y: localRect.midY)
            .blendMode(.destinationOut)
    }
}

