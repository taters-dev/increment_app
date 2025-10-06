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
            // First load the basic data
            try? await workoutStore.load()
            try? await userProfileStore.load()
            
            // Then restore the complete app state
            let (selectedWorkoutDay, shouldRestoreActiveWorkout) = appStateManager.restoreState(
                workoutStore: workoutStore,
                userProfileStore: userProfileStore
            )        }
    }
    
}

#Preview {
    MainTabView()
        .environmentObject(WorkoutStore())
        .environmentObject(UserProfileStore())
} 