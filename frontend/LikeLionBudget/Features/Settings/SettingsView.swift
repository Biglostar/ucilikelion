//
//  SettingsView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore

    @State private var showPrivacySheet = false
    @State private var showPlaidSheet = false
    @State private var showPoliciesSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {

                    VStack(spacing: 0) {

                        sectionHeader("개인정보 관리", trailing: settings.settings.privacyLowMode ? "Low" : "Custom")
                        Toggle("개인정보 보호 모드", isOn: bindingPrivacyLow)
                            .tint(Theme.progressFill)

                        Text("ON이면 데이터 저장/표시를 최소화하는 모드")
                            .font(.caption)
                            .foregroundStyle(Theme.text.opacity(0.65))

                        Button { showPrivacySheet = true } label: {
                            lineButton("세부 설정 보기")
                        }
                        .buttonStyle(.plain)

                        Divider().opacity(0.18).padding(.vertical, 12)

                        sectionHeader("Plaid 연결 관리", trailing: settings.settings.plaidConnected ? "Connected" : "Not Connected")

                        HStack {
                            Text(settings.settings.plaidConnected ? "연결됨 ✅" : "연결 안됨")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(settings.settings.plaidConnected ? Theme.progressFill : Theme.text.opacity(0.65))
                            Spacer()
                            Button { showPlaidSheet = true } label: {
                                Text(settings.settings.plaidConnected ? "관리" : "연결")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(Color.black.opacity(0.07))
                                    )
                                    .foregroundStyle(Theme.progressFill)
                            }
                            .buttonStyle(.plain)
                        }

                        Text("Plaid Link 붙이는 곳")
                            .font(.caption)
                            .foregroundStyle(Theme.text.opacity(0.65))

                        Divider().opacity(0.18).padding(.vertical, 12)

                        sectionHeader("알림 설정", trailing: settings.settings.notificationsEnabled ? "ON" : "OFF")
                        Toggle("알림 전체 ON/OFF", isOn: bindingNotificationsEnabled)
                            .tint(Theme.progressFill)

                        Divider().opacity(0.18).padding(.vertical, 12)

                        sectionHeader("잔소리 강도", trailing: settings.settings.naggingLevel.displayNameKR)
                        NaggingLevelChips(selected: bindingNaggingLevel)

                        Text(sampleMessage(for: settings.settings.naggingLevel))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(toneColor(for: settings.settings.naggingLevel))
                            .softDividerBox(corner: 8)

                        Divider().opacity(0.18).padding(.vertical, 12)

                        sectionHeader("이용 약관 및 정책", trailing: "Low")
                        Button { showPoliciesSheet = true } label: {
                            lineButton("보기")
                        }
                        .buttonStyle(.plain)

                        Text("약관/정책은 외부 링크 또는 앱 내 문서로 연결 예정.")
                            .font(.caption)
                            .foregroundStyle(Theme.text.opacity(0.65))
                    }
                    .padding(14)
                    .beigeContainer(corner: 8)
                    .sheet(isPresented: $showPrivacySheet) {
                        SimpleSheet(title: "개인정보 관리", bodyText: "세부 옵션(예: 로그 저장, 데이터 익명화 등)")
                    }
                    .sheet(isPresented: $showPlaidSheet) {
                        PlaidMockSheet(settings: settings)
                    }
                    .sheet(isPresented: $showPoliciesSheet) {
                        SimpleSheet(title: "이용 약관 및 정책", bodyText: "여기에 약관/정책 내용")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
            .background(Color.white)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("설정")
                        .font(.custom(Theme.fontLaundry, size: 26))
                        .foregroundStyle(Theme.rose)
                }
            }
        }
    }

    // MARK: - Bindings
    private var bindingPrivacyLow: Binding<Bool> {
        Binding(get: { settings.settings.privacyLowMode },
                set: { settings.settings.privacyLowMode = $0 })
    }

    private var bindingNotificationsEnabled: Binding<Bool> {
        Binding(get: { settings.settings.notificationsEnabled },
                set: { settings.settings.notificationsEnabled = $0 })
    }

    private var bindingNaggingLevel: Binding<NaggingLevel> {
        Binding(get: { settings.settings.naggingLevel },
                set: { settings.settings.naggingLevel = $0 })
    }

    // MARK: - UI helpers
    private func sectionHeader(_ title: String, trailing: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.custom(Theme.fontLaundry, size: 16))
                .foregroundStyle(Theme.text)
            Spacer()
            Text(trailing)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.text.opacity(0.6))
        }
    }

    private func lineButton(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.progressFill)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.text.opacity(0.6))
        }
        .softDividerBox(corner: 8)
    }

    private func sampleMessage(for level: NaggingLevel) -> String {
        switch level {
        case .mild: return "오늘은 괜찮아. 그래도 조금만 아껴보자"
        case .medium: return "이번 달 조절 ㄱㄱ"
        case .spicy: return "뭐함??????????"
        }
    }

    private func toneColor(for level: NaggingLevel) -> Color {
        switch level {
        case .mild: return Theme.progressFill
        case .medium: return .orange
        case .spicy: return .red
        }
    }
}

private struct NaggingLevelChips: View {
    @Binding var selected: NaggingLevel

    var body: some View {
        HStack(spacing: 8) {
            chip(.mild, "순한맛")
            chip(.medium, "중간맛")
            chip(.spicy, "매운맛")
        }
    }

    private func chip(_ lv: NaggingLevel, _ title: String) -> some View {
        Button {
            selected = lv
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selected == lv ? Theme.progressFill : Theme.progressBG)
                .foregroundStyle(selected == lv ? Color.white : Theme.progressFill)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.black.opacity(0.06))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sheets

private struct SimpleSheet: View {
    let title: String
    let bodyText: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView { Text(bodyText).padding(16) }
                .background(Color.white)
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("닫기") { dismiss() }
                            .foregroundStyle(Theme.progressFill)
                    }
                }
        }
    }
}

private struct PlaidMockSheet: View {
    @ObservedObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Plaid 연결은 나중에")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text.opacity(0.65))

                Toggle("Plaid 연결됨 (Mock)", isOn: Binding(
                    get: { settings.settings.plaidConnected },
                    set: { settings.settings.plaidConnected = $0 }
                ))
                .tint(Theme.progressFill)
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 20)
            .background(Color.white)
            .navigationTitle("Plaid 연결 관리")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(Theme.progressFill)
                }
            }
        }
    }
}
