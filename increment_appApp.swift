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
    @StateObject private var toastManager = ToastManager()

    init() {
        // Inject ToastManager into stores after initialization
        // This is done here to ensure @StateObject is initialized first
    }

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
            .environmentObject(toastManager)
            .onAppear {
                // Inject ToastManager into stores after view appears
                workoutStore.toastManager = toastManager
                userProfileStore.toastManager = toastManager
            }
            .overlay(alignment: .top) {
                // Error banner at top
                if let error = toastManager.currentError {
                    ErrorBanner(error: error) {
                        toastManager.dismissError()
                    }
                    .padding(.top, 8)
                    .animation(.spring(), value: toastManager.currentError != nil)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Success banner at top
                if let message = toastManager.successMessage {
                    SuccessBanner(message: message) {
                        toastManager.dismissSuccess()
                    }
                    .padding(.top, 8)
                    .animation(.spring(), value: toastManager.successMessage != nil)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .overlay {
                // Loading overlay (full screen)
                if toastManager.isLoading {
                    LoadingOverlay(message: toastManager.loadingMessage)
                }
            }
            .preferredColorScheme(.light)
            .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
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
