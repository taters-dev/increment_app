import Foundation
import SwiftUI

struct UserProfile: Codable {
    var name: String
    var email: String
    var bio: String
    var workoutSplit: [WorkoutDay]
    var goals: [ExerciseGoal]
    var bodyWeightGoal: BodyWeightGoal?
    var profileImageURL: String?
    
    struct WorkoutDay: Codable, Identifiable, Equatable {
        var id = UUID()
        var name: String
        var exercises: [ExerciseTemplate]
        
        static func fromSupabase(data: [String: Any]) -> WorkoutDay? {
            guard let idString = data["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let name = data["name"] as? String else {
                return nil
            }
            
            var exercises: [ExerciseTemplate] = []
            if let exercisesData = data["exercises"] as? [[String: Any]] {
                exercises = exercisesData.compactMap { ExerciseTemplate.fromSupabase(data: $0) }
            }
            
            return WorkoutDay(id: id, name: name, exercises: exercises)
        }
    }
    
    static func fromSupabase(data: [String: Any]) -> UserProfile? {
        guard let name = data["name"] as? String,
              let email = data["email"] as? String else {
            return nil
        }
        
        let bio = data["bio"] as? String ?? ""
        
        var goals: [ExerciseGoal] = []
        if let goalsData = data["goals"] as? [[String: Any]] {
            goals = goalsData.compactMap { ExerciseGoal.fromSupabase(data: $0) }
        }
        
        var workoutSplit: [WorkoutDay] = []
        if let workoutSplitData = data["workout_split"] as? [[String: Any]] {
            workoutSplit = workoutSplitData.compactMap { WorkoutDay.fromSupabase(data: $0) }
        }
        
        var bodyWeightGoal: BodyWeightGoal?
        if let bodyWeightGoalData = data["body_weight_goal"] as? [String: Any] {
            bodyWeightGoal = BodyWeightGoal.fromSupabase(data: bodyWeightGoalData)
        }
        
        let profileImageURL = data["profile_image_url"] as? String
        
        return UserProfile(
            name: name,
            email: email,
            bio: bio,
            workoutSplit: workoutSplit,
            goals: goals,
            bodyWeightGoal: bodyWeightGoal,
            profileImageURL: profileImageURL
        )
    }
}

struct ExerciseGoal: Codable, Identifiable {
    var id = UUID()
    var exerciseName: String
    var targetWeight: Double
    var currentWeight: Double
    
    var progressPercentage: Double {
        (currentWeight / targetWeight) * 100
    }
    
    static func fromSupabase(data: [String: Any]) -> ExerciseGoal? {        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let exerciseName = data["exercise_name"] as? String,
              let targetWeight = data["target_weight"] as? Double,
              let currentWeight = data["current_weight"] as? Double else {
            return nil
        }
        return ExerciseGoal(
            id: id,
            exerciseName: exerciseName,
            targetWeight: targetWeight,
            currentWeight: currentWeight
        )
    }
}

struct BodyWeightGoal: Codable {
    var targetWeight: Double
    var currentWeight: Double
    var startingWeight: Double
    var startDate: Date
    var targetDate: Date
    
    var progressPercentage: Double {
        let isWeightLossGoal = targetWeight < startingWeight
        let totalChange = abs(targetWeight - startingWeight)
        let currentChange = isWeightLossGoal ? 
            abs(startingWeight - currentWeight) : // For weight loss
            abs(currentWeight - startingWeight)   // For weight gain
        
        guard totalChange > 0 else { return 0 }
        return min((currentChange / totalChange) * 100, 100)
    }
    
    static func fromSupabase(data: [String: Any]) -> BodyWeightGoal? {        guard let targetWeight = data["target_weight"] as? Double,
              let currentWeight = data["current_weight"] as? Double,
              let startingWeight = data["starting_weight"] as? Double,
              let startDateString = data["start_date"] as? String,
              let startDate = ISO8601DateFormatter().date(from: startDateString),
              let targetDateString = data["target_date"] as? String,
              let targetDate = ISO8601DateFormatter().date(from: targetDateString) else {
            return nil
        }
        return BodyWeightGoal(
            targetWeight: targetWeight,
            currentWeight: currentWeight,
            startingWeight: startingWeight,
            startDate: startDate,
            targetDate: targetDate
        )
    }
}

@MainActor
class UserProfileStore: ObservableObject, Sendable {
    @Published var profile: UserProfile?
    @Published var lastError: String?
    private var saveTask: Task<Void, Error>?
    private let supabaseStore = SupabaseStore.shared
    
    func saveProfile() async {        if let profile = profile {        }
        do {
            try await save()            // Also sync to Supabase
            if let profile = profile {                try await supabaseStore.syncProfile(profile)            } else {            }
            lastError = nil
        } catch {
            lastError = "Failed to save profile: \(error.localizedDescription)"        }
    }
    
    private static func fileURL() throws -> URL {
        let url = try FileManager.default.url(for: .documentDirectory,
                                  in: .userDomainMask,
                                  appropriateFor: nil,
                                  create: false)
            .appendingPathComponent("profile.data")
        return url
    }
    
    func load() async throws {        // Check if user is authenticated
        guard supabaseStore.authManager.isAuthenticated,
              let currentUser = supabaseStore.authManager.currentUser else {            // Fallback to local storage
            let task = Task<UserProfile?, Error> {
                let fileURL = try Self.fileURL()
                guard let data = try? Data(contentsOf: fileURL) else {                    return nil
                }
                let profile = try JSONDecoder().decode(UserProfile.self, from: data)
                return profile
            }
            let profile = try await task.value
            self.profile = profile
            
            if let profile = profile {            } else {            }
            return
        }        // First try to load from Supabase
        do {
            if let supabaseProfile = try await supabaseStore.fetchProfile() {
                self.profile = supabaseProfile
                // Save to local storage as backup
                try await save()
                return
            } else {            }
        } catch {        }
        
        // Fallback to local storage
        let task = Task<UserProfile?, Error> {
            let fileURL = try Self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {                return nil
            }
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            return profile
        }
        let profile = try await task.value
        self.profile = profile
        
        if let profile = profile {        } else {        }
        
        // Sync local data to Supabase in background
        Task {
            if let profile = profile {
                try? await supabaseStore.syncProfile(profile)
            }
        }
    }
    
    func loadLocalOnly() async throws {
        // Fast local-only loading for startup performance
        let task = Task<UserProfile?, Error> {
            let fileURL = try Self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return nil
            }
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            return profile
        }
        let profile = try await task.value
        self.profile = profile
    }
    
    func save() async throws {
        // Cancel any pending save operation
        saveTask?.cancel()
        
        // Create a new save task
        saveTask = Task {
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second debounce
            let data = try JSONEncoder().encode(profile)
            let outfile = try Self.fileURL()
            try data.write(to: outfile)
        }
        
        try await saveTask?.value
    }
    
    // Helper methods to update profile data
    func updateProfile(_ newProfile: UserProfile) {
        profile = newProfile
        Task { @MainActor in
            await saveProfile()
        }
    }
    
    func updateGoals(_ goals: [ExerciseGoal]) {
        profile?.goals = goals
        Task { @MainActor in
            await saveProfile()
        }
    }
    
    func updateBodyWeightGoal(_ goal: BodyWeightGoal?) {
        profile?.bodyWeightGoal = goal
        Task { @MainActor in
            await saveProfile()
        }
    }
    
    func updateWorkoutSplit(_ split: [UserProfile.WorkoutDay]) {
        profile?.workoutSplit = split
        Task { @MainActor in
            await saveProfile()
        }
    }
    
    func updateProfileImage(_ imageData: Data?) {
        guard let imageData else {
            profile?.profileImageURL = nil
            Task { @MainActor in
                await saveProfile()
            }
            return
        }

        Task { @MainActor in
            do {
                let url = try await supabaseStore.uploadProfileImage(imageData)
                profile?.profileImageURL = url
                await saveProfile()
            } catch {
                lastError = "Failed to upload profile image: \(error.localizedDescription)"
            }
        }
    }
    
    func reset() {
        profile = nil
        lastError = nil
        saveTask?.cancel()
        saveTask = nil
        
        // Delete the stored profile file
        Task {
            do {
                let fileURL = try Self.fileURL()
                try? FileManager.default.removeItem(at: fileURL)
            } catch {
                // Ignore errors when deleting file
            }
        }
        
        // Note: We don't clear Supabase data here as it's user-specific
        // Supabase data is automatically filtered by user_id
    }
} 
