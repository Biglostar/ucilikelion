//
//  LikeLionBudgetApp.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import SwiftUI
import UIKit
import GoogleSignIn
import FirebaseCore
import FirebaseMessaging

@main
struct LikeLionBudgetApp: App {
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var tutorialStore = TutorialStore()

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsStore)
                .environmentObject(tutorialStore)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

// MARK: - FCM AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        return true
    }

    // FCM 토큰 수신(앱 실행 시 / 토큰 갱신 시) → 로그인 상태면 백엔드로 전송
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        PushTokenRegistrar.upload(token)
    }

    // 앱이 포그라운드일 때도 배너/소리로 알림 표시 (기본값은 표시 안 함)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound, .badge])
    }
}

// MARK: - FCM 토큰 → 백엔드 등록

/// `/api/users/fcm-token`은 JWT가 필요하므로 로그인 전에 받은 토큰은 업로드가 실패한다.
/// 로그인 직후 `syncCurrentToken()`을 호출해서 다시 보내야 한다.
enum PushTokenRegistrar {
    /// 현재 FCM 토큰을 가져와 업로드 (로그인 성공 직후 호출)
    static func syncCurrentToken() {
        guard FirebaseApp.app() != nil else { return }
        Messaging.messaging().token { token, error in
            if let error {
                print("[FCM] 토큰 조회 실패: \(error)")
                return
            }
            if let token { upload(token) }
        }
    }

    static func upload(_ token: String) {
        guard AuthToken.current != nil else {
            print("[FCM] 로그인 전이라 토큰 업로드 보류 (로그인 후 재시도)")
            return
        }
        Task {
            do {
                try await APIClient().updateFCMToken(token)
                print("[FCM] 토큰 업로드 완료")
            } catch {
                print("[FCM] 토큰 업로드 실패: \(error)")
            }
        }
    }
}
