//
//  HomeBubbleLayout.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/1/26.
//

import Foundation

struct HomeBubbleLayout: Codable {
    var bubbleX: Double
    var bubbleY: Double
    var tailX: Double
    var tailY: Double

    static func `default`(level: Int) -> HomeBubbleLayout {
        Self.provider.layout(for: level)
    }

    private static let provider: HomeBubbleLayoutProviding = DefaultBubbleLayoutProvider()
}

protocol HomeBubbleLayoutProviding {
    func layout(for level: Int) -> HomeBubbleLayout
}

private let bubbleTailGap: Double = 0.10

private struct DefaultBubbleLayoutProvider: HomeBubbleLayoutProviding {
    private let layouts: [HomeBubbleLayout] = [
        HomeBubbleLayout(bubbleX: 0.78, bubbleY: 0.20, tailX: 0.70, tailY: 0.20 + bubbleTailGap),
        HomeBubbleLayout(bubbleX: 0.78, bubbleY: 0.20, tailX: 0.68, tailY: 0.20 + bubbleTailGap),
        HomeBubbleLayout(bubbleX: 0.78, bubbleY: 0.21, tailX: 0.70, tailY: 0.21 + bubbleTailGap),
        HomeBubbleLayout(bubbleX: 0.78, bubbleY: 0.14, tailX: 0.68, tailY: 0.14 + bubbleTailGap),
        HomeBubbleLayout(bubbleX: 0.78, bubbleY: 0.18, tailX: 0.68, tailY: 0.18 + bubbleTailGap),
    ]

    func layout(for level: Int) -> HomeBubbleLayout {
        let i = min(max(level, 0), layouts.count - 1)
        return layouts[i]
    }
}
