//
//  LikeLionBudgetApp.swift
//  LikeLionBudget
//
//  Created by samuel kim on 1/13/26.
//

import SwiftUI
import UIKit

@main
struct LikeLionBudgetApp: App {
    @StateObject private var onboardingStore = OnboardingStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(onboardingStore)
        }
    }
}
