import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var workoutStore: WorkoutStore
    @EnvironmentObject var userProfileStore: UserProfileStore
    @EnvironmentObject var appStateManager: AppStateManager
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .task {
            // Load local data first for instant UI
            await loadLocalDataFirst()
            
            // Then sync with Supabase in background (non-blocking)
            Task.detached {
                await syncWithSupabase()
            }
            
            // Restore app state after local data is loaded
            let (selectedWorkoutDay, shouldRestoreActiveWorkout) = appStateManager.restoreState(
                workoutStore: workoutStore,
                userProfileStore: userProfileStore
            )
        }
    }
    
    private func loadLocalDataFirst() async {
        // Load local data in parallel for faster startup
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                do {
                    try await workoutStore.loadLocalOnly()
                } catch {
                    // Handle error silently
                }
            }
            
            group.addTask {
                do {
                    try await userProfileStore.loadLocalOnly()
                } catch {
                    // Handle error silently
                }
            }
        }
    }
    
    private func syncWithSupabase() async {
        // Sync with Supabase in background without blocking UI
        do {
            try await workoutStore.load(forceReload: true)
            try await userProfileStore.load()
        } catch {
            // Handle error silently
        }
    }
    
}

#Preview {
    MainTabView()
        .environmentObject(WorkoutStore())
        .environmentObject(UserProfileStore())
} 
