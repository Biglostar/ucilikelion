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
        FirebaseApp.configure()
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

    // FCM 토큰 수신 → 백엔드 PATCH /api/users/fcm-token 전송
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        Task {
            try? await APIClient().updateFCMToken(token)
        }
    }
}
