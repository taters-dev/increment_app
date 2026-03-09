import Foundation
import Supabase

@MainActor
class WorkoutStore: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var activeWorkout: Workout?

    private let supabaseStore = SupabaseStore.shared
    private var lastLoadTime: Date?
    private var didCleanupDuplicates = false

    // Inject ToastManager for error handling
    var toastManager: ToastManager?

    func uploadProgressPhoto(_ data: Data, for workoutId: UUID) async {
        toastManager?.startLoading("Uploading progress photo...")
        do {
            let url = try await supabaseStore.uploadProgressPhoto(data, workoutId: workoutId)
            var updatedWorkoutToSync: Workout?

            if let index = workouts.firstIndex(where: { $0.id == workoutId }) {
                var updated = workouts[index]
                updated.progressPhotoURL = url
                workouts[index] = updated
                updatedWorkoutToSync = updated
            }

            if var active = activeWorkout, active.id == workoutId {
                active.progressPhotoURL = url
                activeWorkout = active
                if updatedWorkoutToSync == nil {
                    updatedWorkoutToSync = active
                }
            }

            try await saveImmediate()
            if let workoutToSync = updatedWorkoutToSync {
                try await supabaseStore.syncWorkouts([workoutToSync])
            } else {
                try await supabaseStore.syncWorkouts(workouts)
            }
            lastLoadTime = Date()
            toastManager?.stopLoading()
            toastManager?.showSuccess("Progress photo uploaded successfully")
        } catch {
            toastManager?.stopLoading()
            toastManager?.showError(.storage(error.localizedDescription))
        }
    }
    
    func saveWorkouts() async {
        do {
            try await saveImmediate()
            try await supabaseStore.syncWorkouts(workouts)
            lastLoadTime = Date()
        } catch {
            toastManager?.showError(.storage(error.localizedDescription))
        }
    }
    
    func saveImmediate() async throws {
        let data = try JSONEncoder().encode(workouts)
        let outfile = try Self.fileURL()
        try data.write(to: outfile, options: .completeFileProtection)
    }
    
    private static func fileURL() throws -> URL {
        let url = try FileManager.default.url(for: .documentDirectory,
                                  in: .userDomainMask,
                                  appropriateFor: nil,
                                  create: false)
            .appendingPathComponent("workouts.data")
        return url
    }
    
    func load(forceReload: Bool = false) async throws {
        if !forceReload, let lastLoad = lastLoadTime, Date().timeIntervalSince(lastLoad) < 30 {
            return
        }
        
        lastLoadTime = Date()
        
        guard supabaseStore.authManager.isAuthenticated,
              supabaseStore.authManager.currentUser != nil else {
            let task = Task<[Workout], Error> {
                let fileURL = try Self.fileURL()
                guard let data = try? Data(contentsOf: fileURL) else {
                    return []
                }
                let workouts = try JSONDecoder().decode([Workout].self, from: data)
                return workouts
            }
            let workouts = try await task.value
            self.workouts = workouts
            return
        }
        
        do {
            if !didCleanupDuplicates {
                didCleanupDuplicates = true
                Task {
                    try? await supabaseStore.cleanupDuplicateWorkouts()
                }
            }
            let supabaseWorkouts = try await supabaseStore.fetchWorkouts()
            
            let localTask = Task<[Workout], Error> {
                let fileURL = try Self.fileURL()
                guard let data = try? Data(contentsOf: fileURL) else {
                    return []
                }
                let workouts = try JSONDecoder().decode([Workout].self, from: data)
                return workouts
            }
            let localWorkouts = try await localTask.value
            
            if !localWorkouts.isEmpty {
                var mergedWorkouts = supabaseWorkouts
                
                for localWorkout in localWorkouts {
                    if let existingIndex = mergedWorkouts.firstIndex(where: { $0.id == localWorkout.id }) {
                        mergedWorkouts[existingIndex] = localWorkout
                    } else {
                        mergedWorkouts.append(localWorkout)
                    }
                }
                
                self.workouts = mergedWorkouts
                try await supabaseStore.syncWorkouts(mergedWorkouts)
            } else {
                self.workouts = supabaseWorkouts
            }
            
            try await save()
            restoreActiveWorkout()
            return
        } catch {
            // Fallback to local storage
            let task = Task<[Workout], Error> {
                let fileURL = try Self.fileURL()
                guard let data = try? Data(contentsOf: fileURL) else {
                    return []
                }
                let workouts = try JSONDecoder().decode([Workout].self, from: data)
                return workouts
            }
            let workouts = try await task.value
            self.workouts = workouts
            restoreActiveWorkout()
            
            Task {
                try? await supabaseStore.syncWorkouts(workouts)
            }
        }
    }
    
    func save() async throws {
        let data = try JSONEncoder().encode(workouts)
        let outfile = try Self.fileURL()
        try data.write(to: outfile, options: .completeFileProtection)
    }
    
    func loadLocalOnly() async throws {
        // Fast local-only loading for startup performance
        let task = Task<[Workout], Error> {
            let fileURL = try Self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return []
            }
            let workouts = try JSONDecoder().decode([Workout].self, from: data)
            return workouts
        }
        let workouts = try await task.value
        self.workouts = workouts
        restoreActiveWorkout()
    }
    
    func reset() {
        workouts = []
        activeWorkout = nil
        lastLoadTime = nil

        Task {
            try? FileManager.default.removeItem(at: try Self.fileURL())
        }
    }
    
    func updateActiveWorkout(_ workout: Workout) {
        activeWorkout = workout
        
        Task { @MainActor in
            await saveActiveWorkout()
        }
    }
    
    func saveActiveWorkout() async {
        guard let workout = activeWorkout else { return }
        
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[index] = workout
        } else {
            workouts.append(workout)
        }
        
        await saveWorkouts()
    }
    
    func restoreActiveWorkout() {
        let exerciseWorkouts = workouts.filter { workout in
            !workout.name.contains("Weight Update") && !workout.name.contains("Progress Photo")
        }

        let workoutToRestore = exerciseWorkouts.max(by: { $0.date < $1.date })
        
        if let workout = workoutToRestore, activeWorkout == nil {
            activeWorkout = workout
        }
    }
    
    func deleteWorkout(_ workout: Workout) {
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts.remove(at: index)

            Task { @MainActor in
                let displayName = workout.name.isEmpty ? "workout" : "\"\(workout.name)\""
                toastManager?.startLoading("Deleting \(displayName)...")
                do {
                    try await saveImmediate()
                } catch {
                    // If local save fails, still attempt remote delete to keep state consistent
                }

                do {
                    try await supabaseStore.deleteWorkout(workout)
                    toastManager?.stopLoading()
                    toastManager?.showSuccess("Deleted \(displayName)")
                } catch {
                    toastManager?.stopLoading()
                    toastManager?.showError(.storage("Failed to delete workout: \(error.localizedDescription)"))
                }
            }
        }
    }
}
