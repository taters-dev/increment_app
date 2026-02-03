import Foundation
import Supabase

@MainActor
class WorkoutStore: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var activeWorkout: Workout?
    @Published var lastError: String?
    
    private let supabaseStore = SupabaseStore.shared
    private var lastLoadTime: Date?
    private var didCleanupDuplicates = false

    func uploadProgressPhoto(_ data: Data, for workoutId: UUID) async {
        do {
            let url = try await supabaseStore.uploadProgressPhoto(data, workoutId: workoutId)
            if let index = workouts.firstIndex(where: { $0.id == workoutId }) {
                workouts[index].progressPhotoURL = url
            }

            if var active = activeWorkout, active.id == workoutId {
                active.progressPhotoURL = url
                activeWorkout = active
            }

            await saveWorkouts()
        } catch {
            lastError = "Failed to upload progress photo: \(error.localizedDescription)"
        }
    }
    
    func saveWorkouts() async {
        do {
            try await saveImmediate()
            try await supabaseStore.syncWorkouts(workouts)
            lastError = nil
            lastLoadTime = Date()
        } catch {
            lastError = "Failed to save workouts: \(error.localizedDescription)"
        }
    }
    
    func saveImmediate() async throws {
        let data = try JSONEncoder().encode(workouts)
        let outfile = try Self.fileURL()
        try data.write(to: outfile)
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
              let currentUser = supabaseStore.authManager.currentUser else {
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
        try data.write(to: outfile)
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
        lastError = nil
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
        let today = Calendar.current.startOfDay(for: Date())
        
        let todaysWorkouts = workouts.filter { workout in
            Calendar.current.isDate(workout.date, inSameDayAs: today)
        }
        
        let exerciseWorkouts = todaysWorkouts.filter { workout in
            !workout.name.contains("Weight Update") && !workout.name.contains("Progress Photo")
        }
        
        let workoutToRestore = exerciseWorkouts.first ?? todaysWorkouts.first
        
        if let workout = workoutToRestore, activeWorkout == nil {
            activeWorkout = workout
        }
    }
    
    func deleteWorkout(_ workout: Workout) {
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts.remove(at: index)
            
            Task { @MainActor in
                await saveWorkouts()
                
                do {
                    try await supabaseStore.deleteWorkout(workout)
                } catch {
                    lastError = "Failed to delete workout from Supabase: \(error.localizedDescription)"
                }
            }
        }
    }
}
