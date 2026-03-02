//
//  SettingsView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/21/26.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingStandard) {
                    settingsCardContent
                }
                .padding(.horizontal, Theme.screenHorizontal)
                .padding(.top, Theme.screenTop + Theme.screenTopNavExtra)
                .padding(.bottom, Theme.screenBottom)
            }
            .background(Color.white)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("설정")
                        .font(.custom(Theme.fontLaundry, size: Theme.titleSize))
                        .foregroundStyle(Theme.rose)
                }
            }
        }
    }

    // MARK: - 설정 카드 (개인정보 / 알림 / 잔소리 / 약관)

    private var settingsCardContent: some View {
        VStack(spacing: 0) {
            NavigationLink {
                PersonalInfoView(settings: settings)
            } label: {
                settingsRow(title: "개인정보", trailing: .chevron)
            }

            settingsDivider()

            HStack {
                Text("전체 알림 설정")
                    .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                    .foregroundStyle(Theme.text)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { settings.settings.notificationsEnabled },
                    set: { settings.settings.notificationsEnabled = $0 }
                ))
                .tint(Theme.progressFill)
            }
            .padding(.horizontal, Theme.cardInnerHorizontal)
            .padding(.vertical, Theme.cardRowVertical)

            settingsDivider()

            naggingSection

            settingsDivider()

            NavigationLink {
                TermsPolicyView(contentType: .unified)
            } label: {
                settingsRow(title: "이용 약관 및 정책", trailing: .chevron)
            }
        }
        .padding(.vertical, Theme.spacingMedium)
        .background(Theme.beige)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                .stroke(Color.black.opacity(Theme.strokeOpacityCard), lineWidth: Theme.strokeLineWidth)
        )
    }

    private var naggingSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingRegular) {
            Text("잔소리 강도 조정")
                .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                .foregroundStyle(Theme.text)
                .padding(.horizontal, Theme.cardInnerHorizontal)
                .padding(.top, Theme.cardRowVertical)

            NaggingLevelChips(selected: Binding(
                get: { settings.settings.naggingLevel },
                set: { settings.settings.naggingLevel = $0 }
            ))

            naggingExampleBox
        }
    }

    private var naggingExampleBox: some View {
        Text(sampleMessage(for: settings.settings.naggingLevel))
            .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
            .fontWeight(.medium)
            .foregroundStyle(toneColor(for: settings.settings.naggingLevel))
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.75)
            .padding(.vertical, Theme.spacingSmall + 4)
            .padding(.horizontal, Theme.spacingRegular)
            .frame(maxWidth: .infinity)
            .background(Theme.progressBG.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .stroke(Color.black.opacity(Theme.strokeOpacityBorder))
            )
            .padding(.horizontal, Theme.cardInnerHorizontal)
            .padding(.bottom, Theme.cardRowVertical)
    }

    private enum RowTrailing {
        case chevron
    }

    // MARK: - Helpers (settingsRow / sampleMessage / toneColor / segment)

    private func settingsRow(title: String, trailing: RowTrailing) -> some View {
        HStack {
            Text(title)
                .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                .foregroundStyle(Theme.text)
            Spacer()
            if case .chevron = trailing {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.text.opacity(0.6))
            }
        }
        .padding(.horizontal, Theme.cardInnerHorizontal)
        .padding(.vertical, Theme.cardRowVertical)
    }

    private func sampleMessage(for level: NaggingLevel) -> String {
        switch level {
        case .mild: return "예시: 오늘은 괜찮아. 그래도 조금만 아껴보자"
        case .medium: return "예시: 이번 달 조절 ㄱㄱ"
        case .spicy: return "예시: 너 왜 그러고 사냐? 머리가 비었음? 지갑 좀 작작 열어 좀:"
        }
    }

    private func toneColor(for level: NaggingLevel) -> Color {
        switch level {
        case .mild: return Theme.progressFill
        case .medium: return .orange
        case .spicy: return Theme.minus
        }
    }

    private func settingsDivider() -> some View {
        Rectangle()
            .fill(Color.black.opacity(Theme.strokeOpacityBorder))
            .frame(height: 1)
            .padding(.horizontal, Theme.cardInnerHorizontal)
    }
}

// MARK: - 잔소리 강도

private struct NaggingLevelChips: View {
    @Binding var selected: NaggingLevel
    private let pad: CGFloat = 4
    private let segmentCount = 3

    var body: some View {
        GeometryReader { geo in
            let segW = (geo.size.width - pad * 2) / CGFloat(segmentCount)
            let idx = selected.rawValue

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.progressBG)

                Capsule()
                    .fill(Theme.progressFill)
                    .frame(width: segW, height: geo.size.height - pad * 2)
                    .offset(x: pad + CGFloat(idx) * segW)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selected)

                HStack(spacing: 0) {
                    segment(.mild, "순한맛")
                    segment(.medium, "매운맛")
                    segment(.spicy, "팩폭맛")
                }
                .padding(pad)
            }
        }
        .frame(height: 44)
        .clipShape(Capsule())
        .padding(.horizontal, Theme.cardInnerHorizontal)
    }

    private func segment(_ lv: NaggingLevel, _ title: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selected = lv }
        } label: {
            Text(title)
                .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
                .foregroundStyle(selected == lv ? .white : Theme.progressFill)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 개인정보 관리

struct PersonalInfoView: View {
    @ObservedObject var settings: SettingsStore
    @EnvironmentObject private var onboardingStore: OnboardingStore
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var showLogoutDoneAlert = false

    private var displayName: String { settings.settings.userDisplayName ?? "—" }
    private var phone: String { settings.settings.userPhone ?? "—" }
    private var email: String { settings.settings.userEmail ?? "—" }
    private var hasLoggedInUser: Bool {
        settings.settings.userDisplayName != nil || settings.settings.userEmail != nil
    }

    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    Color.clear.frame(height: Theme.PersonalInfo.cardInternalTopClear)
                    VStack(spacing: 0) {
                        infoRow(label: "이름", value: displayName, placeholder: !hasLoggedInUser)
                        personalInfoDivider()
                        infoRow(label: "전화번호", value: phone, placeholder: !hasLoggedInUser)
                        personalInfoDivider()
                        infoRow(label: "이메일", value: email, placeholder: !hasLoggedInUser)
                        personalInfoDivider()
                        Button { showLogoutDoneAlert = true } label: {
                            actionRow(label: "로그아웃")
                        }
                        .buttonStyle(.plain)
                        personalInfoDivider()
                        Button { showDeleteConfirm = true } label: {
                            actionRow(label: "계정 탈퇴")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Theme.cardInnerHorizontal)
                    .padding(.top, Theme.PersonalInfo.cardContentTop)
                    .padding(.bottom, Theme.PersonalInfo.cardContentBottom)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .background(Theme.beige)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
                .padding(.horizontal, Theme.screenHorizontal)
                .padding(.top, Theme.PersonalInfo.cardTop)
                .padding(.bottom, Theme.screenBottom + 16)

                Image("PersonalInfoCharacter")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: Theme.screenWidth - Theme.screenHorizontal * 2 - Theme.PersonalInfo.imageWidthOffset,
                        height: Theme.PersonalInfo.imageHeight
                    )
                    .padding(.top, Theme.PersonalInfo.imageTop)
            }
            .padding(.top, 0)
        }
        .background(Color.white)
        .navigationTitle("개인정보 관리")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("개인정보 관리")
                    .font(.custom(Theme.fontLaundry, size: Theme.titleSize))
                    .foregroundStyle(Theme.rose)
            }
        }
        .tint(Theme.rose)
        .sheet(isPresented: $showDeleteConfirm) {
            AccountDeletionConfirmSheet(
                onCancel: { showDeleteConfirm = false },
                onConfirm: { showDeleteConfirm = false; performAccountDeletion() }
            )
            .presentationDetents([.height(Theme.AccountDeletion.sheetHeight)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.white)
            .presentationCornerRadius(Theme.sheetCornerRadius)
        }
        .alert("로그아웃되었어요", isPresented: $showLogoutDoneAlert) {
            Button("확인") {
                showLogoutDoneAlert = false
                performLogout()
            }
        } message: {
            Text("다시 로그인하면 계정으로 들어갈 수 있어요.")
        }
    }

    private func infoRow(label: String, value: String, placeholder: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                .foregroundStyle(Theme.text)
            Spacer()
            Text(placeholder && value == "—" ? "로그인 후 표시됩니다" : value)
                .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                .foregroundStyle(placeholder && value == "—" ? Theme.text.opacity(0.5) : Theme.text.opacity(0.85))
                .lineLimit(1)
        }
        .padding(.vertical, Theme.buttonVerticalPadding)
    }

    private func actionRow(label: String, isDestructive: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                .foregroundStyle(isDestructive ? Theme.minus : Theme.text)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(isDestructive ? Theme.minus.opacity(0.8) : Theme.text.opacity(0.6))
        }
        .padding(.vertical, Theme.buttonVerticalPadding)
    }

    private func personalInfoDivider() -> some View {
        Rectangle()
            .fill(Color.black.opacity(Theme.strokeOpacityBorder))
            .frame(height: 1)
            .padding(.horizontal, Theme.cardInnerHorizontal)
    }

    private func performLogout() {
        settings.clearGoogleUser()
        onboardingStore.resetPostOnboardingForReLogin()
        dismiss()
    }

    private func performAccountDeletion() {
        // 계정 탈퇴 API 연동 시 여기서 처리
        onboardingStore.resetPostOnboardingForReLogin()
        showDeleteConfirm = false
        dismiss()
    }
}

// MARK: - 계정 탈퇴 확인 시트

private struct AccountDeletionConfirmSheet: View {
    var onCancel: () -> Void
    var onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("계정 탈퇴")
                .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                .fontWeight(.semibold)
                .foregroundStyle(Theme.minus)
                .padding(.top, Theme.AccountDeletion.titleTop)
                .padding(.bottom, Theme.AccountDeletion.titleBottom)

            Rectangle()
                .fill(Color.black.opacity(0.10))
                .frame(height: 1)
                .padding(.horizontal, Theme.AccountDeletion.horizontalPadding)

            VStack(spacing: Theme.AccountDeletion.contentGap) {
                Text("정말 탈퇴하시겠어요?")
                    .font(.custom(Theme.fontLaundry, size: Theme.sectionTitleSize))
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                    .padding(.top, Theme.AccountDeletion.questionTop)

                Text("계정 삭제 시 기존의 모든 정보는 즉시 소멸됩니다.")
                    .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                    .foregroundStyle(Theme.text.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.AccountDeletion.horizontalPadding)

            HStack(spacing: Theme.AccountDeletion.buttonSpacing) {
                Button(action: { onCancel(); dismiss() }) {
                    Text("취소")
                        .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.AccountDeletion.buttonVertical)
                        .foregroundStyle(Theme.progressFill)
                        .background(Theme.progressBG)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Theme.progressFill.opacity(0.5), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button(action: onConfirm) {
                    Text("확인")
                        .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.AccountDeletion.buttonVertical)
                        .foregroundStyle(.white)
                        .background(Theme.minus)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.AccountDeletion.horizontalPadding)
            .padding(.top, Theme.AccountDeletion.buttonTop)
            .padding(.bottom, Theme.AccountDeletion.bottomPadding)
        }
        .background(Color.white)
    }
}

// MARK: - 약관/정책 (TermsPolicyContentType / TermsPolicyContent / TermsPolicyView)

enum TermsPolicyContentType {
    case terms   // 서비스 이용약관
    case privacy // 개인정보처리방침
    case unified // 이용 약관 및 정책 (설정용 통합)
}

enum TermsPolicyContent {
    static let termsFull = """
    꼽주머니 이용약관

    본 문서는 꼽주머니를 이용함에 있어 사용자와 꼽주머니 간의 권리, 의무 및 책임사항을 규정합니다.

    제1조 (목적)
    본 약관은 사용자가 서비스를 통해 본인의 금융 데이터를 통합 관리하고, AI 기반의 분석, 리포트 및 캐릭터 서비스를 이용함에 있어 필요한 제반 사항을 규정함을 목적으로 합니다.

    제2조 (계정 등록 및 인증)
    사용자는 구글 계정을 통한 소셜 로그인 방식을 사용하여 본 서비스에 가입하고 이용할 수 있습니다.
    구글 로그인을 이용할 경우, 사용자는 구글의 서비스 약관 및 개인정보 보호정책에 동의한 것으로 간주됩니다.
    사용자는 본인의 구글 계정 보안에 대한 관리 책임이 있으며, 계정 도용 등으로 인해 발생하는 손해에 대해 꼽주머니는 고의 또는 중과실이 없는 한 책임을 지지 않습니다.

    제3조 (금융 데이터 연동 및 Plaid 서비스)
    사용자는 금융 데이터(은행, 카드 등) 연동을 위해 Plaid, Inc의 서비스를 이용하는 것에 동의합니다.
    데이터 연동 과정에서 발생하는 인증 및 보안은 Plaid의 시스템을 통해 처리되며, 꼽주머니는 사용자의 금융 기관 로그인 정보(ID, 비밀번호 등)를 직접 수집하거나 저장하지 않습니다.
    Plaid를 통해 수집된 데이터의 정확성은 해당 금융 기관 및 Plaid의 시스템 상태에 의존하며, 꼽주머니는 데이터 반영 지연이나 오류에 대해 고의 또는 중과실이 없는 한 책임을 지지 않습니다.

    제4조 (AI 서비스 및 캐릭터 시스템)
    서비스는 사용자의 소비 패턴을 분석하여 캐릭터의 상태를 업데이트하고, 설정된 강도에 따라 알림을 발송합니다.
    AI 서비스는 Google Gemini 모델을 활용하며, 데이터 처리 과정에서 개인을 식별할 수 있는 직접적인 정보(성명, 상세 계좌번호 등)는 제외된 상태로 분석됩니다.
    사용자는 설정창을 통해 알림의 강도를 선택할 수 있으며, 선택한 강도에 따른 메시지 수신 및 캐릭터 상태 변화에 동의합니다.

    제5조 (금융 책임 부인)
    본 서비스는 정보 제공 및 자산 관리 보조를 목적으로 하며, 어떠한 경우에도 전문적인 금융 자문으로 간주될 수 없습니다.
    꼽주머니는 사용자가 서비스를 통해 얻은 정보를 바탕으로 내린 금융적 결정 및 그로 인한 손실에 대해 책임을 지지 않습니다.
    """

    static let privacyFull = """
    꼽주머니 개인정보 처리방침

    제1조 (수집하는 개인정보 항목 및 방법)
    꼽주머니는 서비스 제공을 위해 다음과 같은 정보를 수집 및 처리합니다.
    구글 로그인을 통해 수집되는 정보 (OAuth 2.0):
    필수 항목: 구글 계정 이메일 주소, 고유 사용자 식별자(Google UID).
    선택 항목: 이름(닉네임), 프로필 사진.
    금융 데이터 (Plaid): 계좌 잔액, 거래 내역(금액, 날짜, 카테고리, 거래처 명칭), 금융 기관 명칭.
    사용자 입력 및 설정 정보: 수동 거래 내역(제목, 금액, 메모), 목표 설정 정보, AI 알림 강도 설정값.

    제2조 (개인정보의 수집 및 이용 목적)
    수집된 정보는 다음의 목적을 위해서만 이용됩니다.
    서비스 핵심 기능: 실시간 지출 내역 대시보드, 캘린더 구현, 카테고리별 게이지바 시각화, 월별 지출 리포트, 개인화 목표 설정.
    캐릭터 로직 및 분석: 이전 3개월 평균 소비액 계산 및 실시간 캐릭터 스테이지 판별.
    AI 추천 및 리포트: Gemini AI를 활용한 지출 내역의 자동 카테고리 분류 및 추천, 소비 패턴 분석을 통한 맞춤형 월간/주간 분석 리포트 생성, 설정된 강도에 따른 개인화된 AI 푸시 알림 문구 생성.

    제3조 (개인정보의 제3자 제공 및 위탁)
    꼽주머니는 서비스 제공을 위해 필수적인 경우에 한하여 다음과 같이 개인정보를 제공 및 위탁합니다.
    제공받는 자: Plaid, Inc. / 목적: 금융 기관 데이터 연결 및 거래 내역 수신 위탁.
    제공받는 자: Google LLC (인증/Gemini AI) / 목적: 사용자 구글 계정 인증 처리 및 AI 기반 분석.

    제4조 (데이터 보안 및 보관)
    무비밀번호 원칙: 꼽주머니는 사용자의 구글 계정 비밀번호를 요청하거나 저장하지 않습니다.
    보관 기간: 개인정보는 원칙적으로 회원 탈퇴 시 즉시 파기합니다.

    제5조 (사용자의 권리 - CCPA 준수)
    열람 요청권, 삭제 요청권, 개인정보 판매 거부권 (꼽주머니는 사용자 데이터를 제3자에게 판매하지 않습니다).

    시행일: 2026년 2월 19일
    개발자 및 문의처: https://www.instagram.com/likelion.uci/
    """
}

struct TermsPolicyView: View {
    let contentType: TermsPolicyContentType

    private var displayTitle: String {
        switch contentType {
        case .terms: return "서비스 이용약관"
        case .privacy: return "개인정보처리방침"
        case .unified: return "이용 약관 및 정책"
        }
    }

    private var content: String {
        switch contentType {
        case .terms: return TermsPolicyContent.termsFull
        case .privacy: return TermsPolicyContent.privacyFull
        case .unified: return TermsPolicyContent.termsFull + "\n\n" + TermsPolicyContent.privacyFull
        }
    }

    var body: some View {
        ScrollView {
            Text(content)
                .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.cardPadding)
        }
        .background(Theme.beige)
        .navigationTitle(displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(displayTitle)
                    .font(.custom(Theme.fontLaundry, size: Theme.subscreenTitleSize))
                    .foregroundStyle(Theme.rose)
            }
        }
        .tint(Theme.rose)
    }
}
