//
//  LoginView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/18/26.
//

import SwiftUI
import UIKit
import GoogleSignIn

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    var settingsStore: SettingsStore

    // MARK: - State & Layout

    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    private let fieldCorner: CGFloat = 10
    private let fieldBorderOpacity: Double = 0.2
    private let loginButtonColor = Theme.progressFill

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    header

                    VStack(spacing: Theme.spacingSection) {
                        emailField
                        passwordField
                        loginButton
                        orDivider
                        if let msg = errorMessage {
                            Text(msg)
                                .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                                .foregroundStyle(Color.red)
                                .multilineTextAlignment(.center)
                        }
                        googleButton
                    }
                    .padding(.horizontal, Theme.screenHorizontal)
                    .padding(.top, Theme.spacingLarge)
                    Spacer(minLength: 0)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button { hideKeyboard() } label: {
                    Image(systemName: "chevron.down")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.progressFill)
                }
            }
        }
        .disabled(isSigningIn)
    }

    // MARK: - Subviews (header / fields / buttons)

    private var header: some View {
        HStack {
            Text("로그인")
                .font(.custom(Theme.fontLaundry, size: Theme.titleSize))
                .foregroundStyle(Theme.text)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Theme.text)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.screenHorizontal)
        .padding(.top, Theme.screenTop + Theme.screenTopNavExtra)
        .padding(.bottom, Theme.spacingRegular)
    }

    private var emailField: some View {
        TextField("아이디 (이메일)", text: $email)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
            .foregroundStyle(Theme.text)
            .padding(.horizontal, Theme.cardPadding)
            .padding(.vertical, Theme.buttonVerticalPadding)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: fieldCorner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: fieldCorner, style: .continuous)
                    .stroke(Color.black.opacity(fieldBorderOpacity), lineWidth: 1)
            )
    }

    private var passwordField: some View {
        HStack {
            if isPasswordVisible {
                TextField("비밀번호", text: $password)
                    .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                    .foregroundStyle(Theme.text)
            } else {
                SecureField("비밀번호", text: $password)
                    .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                    .foregroundStyle(Theme.text)
            }

            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.text.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.cardPadding)
        .padding(.vertical, Theme.buttonVerticalPadding)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: fieldCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: fieldCorner, style: .continuous)
                .stroke(Color.black.opacity(fieldBorderOpacity), lineWidth: 1)
        )
    }

    private var loginButton: some View {
        Button {
        } label: {
            Text("로그인하기")
                .font(.custom(Theme.fontLaundry, size: Theme.bodySize))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.buttonVerticalPadding)
                .background(loginButtonColor)
                .clipShape(RoundedRectangle(cornerRadius: fieldCorner, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var orDivider: some View {
        HStack(spacing: Theme.spacingRegular) {
            Rectangle()
                .fill(Color.black.opacity(0.12))
                .frame(height: 1)
            Text("또는")
                .font(.custom(Theme.fontLaundry, size: Theme.smallBodySize))
                .foregroundStyle(Theme.text.opacity(0.7))
            Rectangle()
                .fill(Color.black.opacity(0.12))
                .frame(height: 1)
        }
        .padding(.vertical, Theme.spacingSection)
    }

    private var googleButton: some View {
        Button {
            performGoogleSignIn()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.15), lineWidth: 1)
                    )
                googleLogoImage
            }
        }
        .buttonStyle(.plain)
    }

    private var googleLogoImage: some View {
        Image("GoogleLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 28, height: 28)
    }

    // MARK: - Google Sign-In / Helpers

    private func performGoogleSignIn() {
        errorMessage = nil
        isSigningIn = true

        guard let rootVC = rootViewController else {
            errorMessage = "화면을 불러올 수 없어요."
            isSigningIn = false
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [self] result, error in
            isSigningIn = false
            if let error = error {
                let nsError = error as NSError
                if nsError.code == -5 || nsError.domain == "com.google.GIDSignIn" && nsError.code == -1 {
                    return
                }
                errorMessage = "로그인에 실패했어요. 다시 시도해 주세요."
                return
            }
            guard let result = result else { return }
            let profile = result.user.profile
            settingsStore.setGoogleUser(
                displayName: profile?.name,
                email: profile?.email
            )
            dismiss()
        }
    }

    private var rootViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              var top = window.rootViewController else {
            return nil
        }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
