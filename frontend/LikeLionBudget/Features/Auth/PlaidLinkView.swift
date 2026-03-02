//
//  PlaidLinkView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/18/26.
//

import SwiftUI
import UIKit
import LinkKit

struct PlaidLinkView: SwiftUI.View {
    @SwiftUI.Environment(\.dismiss) private var dismiss
    var settingsStore: SettingsStore?
    var onComplete: (() -> Void)?

    // MARK: - State

    @State private var linkToken: String? = nil
    @State private var isConnecting = false
    @State private var errorMessage: String? = nil
    @State private var linkHandler: Handler? = nil
    @State private var receivedPublicToken: String? = nil

    var body: some View {
        VStack(spacing: Theme.spacingSection) {
            Text("은행 연결")
                .font(.custom(Theme.fontLaundry, size: Theme.titleSize))
                .foregroundStyle(Theme.text)
            Text("Plaid를 통해 계정을 연결합니다.\n연동 준비가 되면 아래 버튼으로 은행을 선택해 연결할 수 있습니다.")
                .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                .foregroundStyle(Theme.text.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let msg = errorMessage {
                Text(msg)
                    .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                    .foregroundStyle(Theme.minus)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer(minLength: Theme.spacingSection)

            if linkToken != nil {
                Button {
                    openPlaidLink()
                } label: {
                    Text("은행 연결하기")
                        .font(.custom(Theme.fontLaundry, size: 15))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.buttonVerticalPadding)
                        .background(Theme.progressFill)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isConnecting)
            }

            Button {
                onComplete?()
                dismiss()
            } label: {
                Text("나중에 하기")
                    .font(.custom(Theme.fontLaundry, size: 15))
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.text.opacity(0.8))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.screenHorizontal)
            .padding(.bottom, Theme.spacingSection)
        }
        .padding(.top, Theme.spacingSection)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.beige)
        .onAppear { fetchLinkToken() }
        .onChange(of: receivedPublicToken) { _, token in
            guard let token else { return }
            handlePlaidSuccess(publicToken: token)
            receivedPublicToken = nil
        }
    }

    // MARK: - Link Token

    private func fetchLinkToken() {
        Task {
            do {
                let response = try await APIClient().createPlaidLinkToken()
                await MainActor.run {
                    linkToken = response.linkToken
                    errorMessage = nil
                }
            } catch let error as APIError {
                await MainActor.run {
                    switch error {
                    case .transport:
                        errorMessage = "서버에 연결할 수 없어요. 백엔드(localhost:3000)가 실행 중인지 확인해 주세요."
                    case .serverStatus(let code):
                        errorMessage = code == 401 ? "로그인이 필요해요." : "서버 오류예요. (\(code))"
                    case .decoding, .invalidURL:
                        errorMessage = "연결 토큰을 불러오지 못했어요."
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "연결 토큰을 불러오지 못했어요."
                }
            }
        }
    }

    /// Plaid Link SDK 연동 시: SDK로 linkToken 넘겨 UI 띄우고, 성공 시 이 메서드 호출
    func handlePlaidSuccess(publicToken: String) {
        isConnecting = true
        Task {
            do {
                let client = APIClient()
                try await client.exchangePlaidPublicToken(publicToken)
                try? await client.syncPlaid()
                await MainActor.run {
                    NotificationCenter.default.post(name: .plaidDidSync, object: nil)
                    settingsStore?.setPlaidConnected(true)
                    onComplete?()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "연동 저장에 실패했어요."
                    isConnecting = false
                }
            }
        }
    }

    // MARK: - LinkKit Open + Success / Exit

    /// LinkKit으로 Link UI 띄우기. 성공 시 onSuccess에서 handlePlaidSuccess(publicToken) 호출됨
    private func openPlaidLink() {
        guard let token = linkToken else { return }
        errorMessage = nil

        var configuration = LinkTokenConfiguration(
            token: token,
            onSuccess: { linkSuccess in
                Task { @MainActor in
                    receivedPublicToken = linkSuccess.publicToken
                }
            }
        )
        configuration.onExit = { linkExit in
            Task { @MainActor in
                if let err = linkExit.error {
                    let msg = err.displayMessage ?? ""
                    errorMessage = msg.isEmpty ? (err.errorMessage ?? "연결이 중단되었어요.") : msg
                }
                linkHandler = nil
            }
        }

        switch Plaid.create(configuration) {
        case .failure:
            errorMessage = "은행 연결을 시작할 수 없어요."
        case .success(let handler):
            linkHandler = handler
            guard let topVC = Self.topViewController else {
                linkHandler = nil
                errorMessage = "화면을 표시할 수 없어요."
                return
            }
            handler.open(presentUsing: LinkKit.PresentationMethod.viewController(topVC))
        }
    }

    // MARK: - Helpers (ViewController)

    private static var topViewController: UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              let root = window.rootViewController else { return nil }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        return top
    }
}

#Preview {
    PlaidLinkView()
}
