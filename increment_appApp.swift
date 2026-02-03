//
//  increment_appApp.swift
//  increment_app
//
//  Created by Tate McCoy on 3/25/25.
//

import SwiftUI

@main
struct increment_appApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var userProfileStore = UserProfileStore()
    @StateObject private var workoutStore = WorkoutStore()
    @StateObject private var appStateManager = AppStateManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    // Show loading screen while checking authentication
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                } else if authManager.isAuthenticated {
                    MainTabView()
                } else {
                    AuthenticationView()
                }
            }
            .environmentObject(authManager)
            .environmentObject(userProfileStore)
            .environmentObject(workoutStore)
            .environmentObject(appStateManager)
            .preferredColorScheme(.light)
            .onChange(of: authManager.isAuthenticated) { isAuthenticated in
                if isAuthenticated {
                    // Reset stores when user signs in/up
                    userProfileStore.reset()
                    workoutStore.reset()
                }
            }
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                            // Save complete app state when app goes to background
                            appStateManager.saveCurrentState(
                                workoutStore: workoutStore,
                                userProfileStore: userProfileStore,
                                selectedWorkoutDay: nil // Will be handled by HomeView
                            )
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                            // Save complete app state when app is about to terminate
                            appStateManager.saveCurrentState(
                                workoutStore: workoutStore,
                                userProfileStore: userProfileStore,
                                selectedWorkoutDay: nil // Will be handled by HomeView
                            )
                        }
        }
    }
}
