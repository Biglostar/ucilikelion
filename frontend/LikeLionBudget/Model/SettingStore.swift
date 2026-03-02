//
//  SettingStore.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/31/26.
//

import Foundation
import Combine

// MARK: - NaggingLevel (잔소리 강도)

enum NaggingLevel: Int, CaseIterable, Identifiable, Codable {
    case mild = 0    // 순한맛
    case medium = 1  // 매운맛
    case spicy = 2   // 팩폭맛

    var id: Int { rawValue }

    var displayNameKR: String {
        switch self {
        case .mild: return "순한맛"
        case .medium: return "매운맛"
        case .spicy: return "팩폭맛"
        }
    }
}

// MARK: - AppSettings

struct AppSettings: Codable {
    var privacyLowMode: Bool
    var notificationsEnabled: Bool
    var naggingLevel: NaggingLevel
    var plaidConnected: Bool
    /// 로그아웃 후 재로그인 시 약관/플레이드 화면 스킵용. 로그아웃해도 초기화하지 않음.
    var hasCompletedTermsAndPlaidOnce: Bool
    var userDisplayName: String?
    var userPhone: String?
    var userEmail: String?

    enum CodingKeys: String, CodingKey {
        case privacyLowMode, notificationsEnabled, naggingLevel, plaidConnected
        case hasCompletedTermsAndPlaidOnce
        case userDisplayName, userPhone, userEmail
    }

    init(privacyLowMode: Bool, notificationsEnabled: Bool, naggingLevel: NaggingLevel, plaidConnected: Bool, hasCompletedTermsAndPlaidOnce: Bool = false, userDisplayName: String? = nil, userPhone: String? = nil, userEmail: String? = nil) {
        self.privacyLowMode = privacyLowMode
        self.notificationsEnabled = notificationsEnabled
        self.naggingLevel = naggingLevel
        self.plaidConnected = plaidConnected
        self.hasCompletedTermsAndPlaidOnce = hasCompletedTermsAndPlaidOnce
        self.userDisplayName = userDisplayName
        self.userPhone = userPhone
        self.userEmail = userEmail
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        privacyLowMode = try c.decode(Bool.self, forKey: .privacyLowMode)
        notificationsEnabled = try c.decode(Bool.self, forKey: .notificationsEnabled)
        naggingLevel = try c.decode(NaggingLevel.self, forKey: .naggingLevel)
        plaidConnected = try c.decode(Bool.self, forKey: .plaidConnected)
        hasCompletedTermsAndPlaidOnce = try c.decodeIfPresent(Bool.self, forKey: .hasCompletedTermsAndPlaidOnce) ?? false
        userDisplayName = try c.decodeIfPresent(String.self, forKey: .userDisplayName)
        userPhone = try c.decodeIfPresent(String.self, forKey: .userPhone)
        userEmail = try c.decodeIfPresent(String.self, forKey: .userEmail)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(privacyLowMode, forKey: .privacyLowMode)
        try c.encode(notificationsEnabled, forKey: .notificationsEnabled)
        try c.encode(naggingLevel, forKey: .naggingLevel)
        try c.encode(plaidConnected, forKey: .plaidConnected)
        try c.encode(hasCompletedTermsAndPlaidOnce, forKey: .hasCompletedTermsAndPlaidOnce)
        try c.encodeIfPresent(userDisplayName, forKey: .userDisplayName)
        try c.encodeIfPresent(userPhone, forKey: .userPhone)
        try c.encodeIfPresent(userEmail, forKey: .userEmail)
    }
}

// MARK: - SettingsStore

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
                plaidConnected: false,
                hasCompletedTermsAndPlaidOnce: false,
                userDisplayName: nil,
                userPhone: nil,
                userEmail: nil
            )
            save()
        }
    }

    // MARK: - Persistence (save / load)

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

    var naggingLevel: NaggingLevel { settings.naggingLevel }
    var notificationsEnabled: Bool { settings.notificationsEnabled }

    // MARK: - 사용자 / Plaid 설정

    func setGoogleUser(displayName: String?, email: String?) {
        settings.userDisplayName = displayName
        settings.userEmail = email
    }

    func clearGoogleUser() {
        settings.userDisplayName = nil
        settings.userEmail = nil
    }

    func setPlaidConnected(_ value: Bool) {
        settings.plaidConnected = value
    }

    /// 약관·플레이드 한 번이라도 완료했으면 true. 로그아웃 후 재로그인 시 약관/플레이드 스킵에 사용.
    func setHasCompletedTermsAndPlaidOnce(_ value: Bool) {
        settings.hasCompletedTermsAndPlaidOnce = value
    }
}
