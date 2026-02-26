//
//  LoginView.swift
//  LikeLionBudget
//
//  Created by samuel kim on 2/18/26.
//

import SwiftUI
import SafariServices
import UIKit

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var showGoogleSignIn = false

    private let fieldCorner: CGFloat = 10
    private let fieldBorderOpacity: Double = 0.2
    private let loginButtonColor = Theme.progressFill

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                VStack(spacing: Theme.spacingSection) {
                    emailField
                    passwordField
                    loginButton
                    orDivider
                    googleButton
                }
                .padding(.horizontal, Theme.screenHorizontal)
                .padding(.top, Theme.spacingLarge)
                Spacer(minLength: 0)
            }
        }
        .sheet(isPresented: $showGoogleSignIn) {
            SafariView(url: googleSignInURL)
        }
    }

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
            // TODO: 이메일/비밀번호 로그인 (백엔드 연동)
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
            showGoogleSignIn = true
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

    /// Asset 카탈로그 이미지셋 이름은 "GoogleLogo" (대문자 G). 2x/3x 비어 있어도 1x로 표시됨.
    private var googleLogoImage: some View {
        Image("GoogleLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 28, height: 28)
    }

    private var googleGColors: LinearGradient {
        LinearGradient(
            colors: [
                Color(llHex: "#4285F4"),
                Color(llHex: "#EA4335"),
                Color(llHex: "#FBBC05"),
                Color(llHex: "#34A853")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 구글 로그인 페이지. 이후 OAuth client_id/redirect_uri 연동 시 교체.
    private var googleSignInURL: URL {
        URL(string: "https://accounts.google.com")!
    }
}

// MARK: - Safari (구글 로그인 페이지 인앱 표시)

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.preferredControlTintColor = UIColor(Theme.rose)
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
