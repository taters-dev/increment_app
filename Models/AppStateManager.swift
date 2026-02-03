import Foundation

@MainActor
class AppStateManager: ObservableObject {
    @Published var isStateLoaded = false
    
    private var appState: AppState?
    
    struct AppState: Codable {
        let selectedWorkoutDay: String?
        let currentWorkout: CurrentWorkoutState?
        let savedAt: Date
    }
    
    struct CurrentWorkoutState: Codable {
        let workoutName: String
        let exercises: [ExerciseState]
        let startTime: Date
        let workoutId: String
    }
    
    struct ExerciseState: Codable {
        let id: String
        let name: String
        let sets: [ExerciseSetState]
    }
    
    struct ExerciseSetState: Codable {
        let id: String
        let weight: Double
        let reps: Int
    }
    
    func saveCurrentState(
        workoutStore: WorkoutStore,
        userProfileStore: UserProfileStore,
        selectedWorkoutDay: UserProfile.WorkoutDay?
    ) {
        let selectedWorkoutDayName = selectedWorkoutDay?.name
        
        let currentWorkoutState: CurrentWorkoutState?
        if let activeWorkout = workoutStore.activeWorkout {
            currentWorkoutState = CurrentWorkoutState(
                workoutName: activeWorkout.name,
                exercises: activeWorkout.exercises.map { exercise in
                    ExerciseState(
                        id: exercise.id.uuidString,
                        name: exercise.name,
                        sets: exercise.sets.map { set in
                            ExerciseSetState(
                                id: set.id.uuidString,
                                weight: set.weight,
                                reps: set.reps
                            )
                        }
                    )
                },
                startTime: activeWorkout.date,
                workoutId: activeWorkout.id.uuidString
            )
        } else {
            currentWorkoutState = nil
        }
        
        let state = AppState(
            selectedWorkoutDay: selectedWorkoutDayName,
            currentWorkout: currentWorkoutState,
            savedAt: Date()
        )
        
        self.appState = state
        saveStateToFile(state)
    }
    
    func restoreState(
        workoutStore: WorkoutStore,
        userProfileStore: UserProfileStore
    ) -> (selectedWorkoutDay: UserProfile.WorkoutDay?, shouldRestoreActiveWorkout: Bool) {
        guard let state = loadStateFromFile() else {
            return (nil, false)
        }
        
        self.appState = state
        let shouldRestoreActiveWorkout = state.currentWorkout != nil
        
        if let currentWorkout = state.currentWorkout {
            // Convert back to app models
            let restoredExercises = currentWorkout.exercises.map { exerciseState in
                Exercise(
                    templateId: UUID(uuidString: exerciseState.id) ?? UUID(),
                    name: exerciseState.name,
                    sets: exerciseState.sets.map { setState in
                        ExerciseSet(
                            id: UUID(uuidString: setState.id) ?? UUID(),
                            reps: setState.reps,
                            weight: setState.weight
                        )
                    },
                    maxWeight: exerciseState.sets.map { $0.weight }.max()
                )
            }
            
            let restoredWorkout = Workout(
                id: UUID(uuidString: currentWorkout.workoutId) ?? UUID(),
                date: currentWorkout.startTime,
                name: currentWorkout.workoutName,
                exercises: restoredExercises,
                notes: nil,
                duration: nil,
                bodyWeight: nil
            )
            
            workoutStore.activeWorkout = restoredWorkout
            
            // Add to workouts array if not already present
            if !workoutStore.workouts.contains(where: { $0.id == restoredWorkout.id }) {
                workoutStore.workouts.append(restoredWorkout)
            }
        }
        
        self.isStateLoaded = true
        return (nil, shouldRestoreActiveWorkout)
    }
    
    private func saveStateToFile(_ state: AppState) {
        guard let url = getStateFileURL() else { return }
        
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: url)
        } catch {
            // Handle error silently in production
        }
    }
    
    private func loadStateFromFile() -> AppState? {
        guard let url = getStateFileURL() else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            let state = try JSONDecoder().decode(AppState.self, from: data)
            return state
        } catch {
            return nil
        }
    }
    
    private func getStateFileURL() -> URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsPath.appendingPathComponent("app_state.json")
    }
    
    func clearAppState() {
        guard let url = getStateFileURL() else { return }
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            // Handle error silently in production
        }
    }
}
