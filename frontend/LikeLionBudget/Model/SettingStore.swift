//
//  SettingStore.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/31/26.
//

import Foundation
import Combine

// 잔소리 강도
enum NaggingLevel: Int, CaseIterable, Identifiable, Codable {
    case mild = 0      // 순한맛
    case medium = 1    // 중간맛
    case spicy = 2     // 매운맛

    var id: Int { rawValue }

    var displayNameKR: String {
        switch self {
        case .mild: return "순한맛"
        case .medium: return "중간맛"
        case .spicy: return "매운맛"
        }
    }
}

// 저장할 설정 모델
struct AppSettings: Codable {
    var privacyLowMode: Bool
    var notificationsEnabled: Bool
    var naggingLevel: NaggingLevel
    var plaidConnected: Bool
}

// 저장/로드 담당
final class SettingsStore: ObservableObject {
    @Published var settings: AppSettings {
        didSet { save() }
    }

    private let key = "LikeLionBudget.AppSettings.v1"

    init() {
        if let loaded = Self.load(key: key) {
            self.settings = loaded
        } else {
            self.settings = AppSettings(
                privacyLowMode: true,
                notificationsEnabled: true,
                naggingLevel: .medium,
                plaidConnected: false
            )
            save()
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("⚠️ Settings save failed:", error)
        }
    }

    private static func load(key: String) -> AppSettings? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(AppSettings.self, from: data)
        } catch {
            print("⚠️ Settings load failed:", error)
            return nil
        }
    }

    // 나중에 연결용 convenience
    var naggingLevel: NaggingLevel { settings.naggingLevel }
    var notificationsEnabled: Bool { settings.notificationsEnabled }
}
