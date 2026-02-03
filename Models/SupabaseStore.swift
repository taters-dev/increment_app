import Foundation
import Supabase

class SupabaseStore: ObservableObject {
    static let shared = SupabaseStore()
    let authManager = AuthenticationManager.shared
    private let supabase = SupabaseConfig.shared.client
    private let profileImagesBucket = "profile-images"
    private let progressPhotosBucket = "progress-photos"
    
    private init() {}
    
    @MainActor
    func syncWorkouts(_ workouts: [Workout]) async throws {
        guard let userId = authManager.currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }

        let supabaseWorkouts = workouts.map { SupabaseWorkout(from: $0, userId: userId.uuidString) }
        do {
            try await supabase.from("workouts")
                .upsert(supabaseWorkouts)
                .execute()
        } catch {
            throw error
        }
    }
    
    @MainActor
    func fetchWorkouts() async throws -> [Workout] {
        guard let userId = authManager.currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let response = try await supabase.from("workouts")
            .select("id,user_id,date,name,exercises,notes,duration,body_weight,progress_photo_url,created_at,updated_at")
            .eq("user_id", value: userId.uuidString)
            .order("date", ascending: false)
            .execute()
        
        let jsonData = response.data
        let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] ?? []
        
        let workouts = jsonArray.compactMap { dataDict in
            return Workout.fromSupabase(data: dataDict)
        }
        return workouts
    }
    
    @MainActor
    func deleteWorkout(_ workout: Workout) async throws {
        guard let userId = authManager.currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let response = try await supabase.from("workouts")
            .delete()
            .eq("id", value: workout.id.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    @MainActor
    func cleanupDuplicateWorkouts() async throws {
        guard let userId = authManager.currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let response = try await supabase.from("workouts")
            .select("*")
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
        
        let jsonData = response.data
        let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] ?? []
        
        var workoutGroups: [String: [[String: Any]]] = [:]
        
        for workoutData in jsonArray {
            guard let dateString = workoutData["date"] as? String,
                  let name = workoutData["name"] as? String else { continue }
            
            let dateOnly = String(dateString.prefix(10))
            let key = "\(dateOnly)-\(name)"
            
            if workoutGroups[key] == nil {
                workoutGroups[key] = []
            }
            workoutGroups[key]?.append(workoutData)
        }
        
        for (key, workouts) in workoutGroups {
            if workouts.count > 1 {
                let workoutsToDelete = Array(workouts.dropFirst())
                
                for workoutToDelete in workoutsToDelete {
                    guard let id = workoutToDelete["id"] as? String else { continue }
                    
                    let _ = try await supabase.from("workouts")
                        .delete()
                        .eq("id", value: id)
                        .eq("user_id", value: userId.uuidString)
                        .execute()
                }
            }
        }
    }
    
    @MainActor
    func syncProfile(_ profile: UserProfile) async throws {
        guard let userId = authManager.currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let supabaseProfile = SupabaseUserProfile(from: profile, userId: userId.uuidString)
        do {
            try await supabase.from("user_profiles")
                .upsert(supabaseProfile)
                .execute()
        } catch {
            throw error
        }
    }
    
    @MainActor
    func fetchProfile() async throws -> UserProfile? {
        guard let userId = authManager.currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }
        
        do {
            let response = try await supabase.from("user_profiles")
                .select("user_id,name,email,bio,profile_image_url,body_weight_goal,goals,workout_split,created_at,updated_at")
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
            
        let jsonData = response.data
        let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]
        
        let profile = UserProfile.fromSupabase(data: jsonDict)
        return profile
        } catch {
            throw error
        }
    }

    @MainActor
    func uploadProfileImage(_ data: Data) async throws -> String {
        guard let userId = authManager.currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }

        let path = "users/\(userId.uuidString)/profile.jpg"
        let options = FileOptions(contentType: "image/jpeg", upsert: true)
        try await supabase.storage
            .from(profileImagesBucket)
            .upload(path, data: data, options: options)

        let publicURL = try supabase.storage
            .from(profileImagesBucket)
            .getPublicURL(path: path)

        return publicURL.absoluteString
    }

    @MainActor
    func uploadProgressPhoto(_ data: Data, workoutId: UUID) async throws -> String {
        guard let userId = authManager.currentUser?.id else {
            throw SupabaseError.notAuthenticated
        }

        let path = "users/\(userId.uuidString)/workouts/\(workoutId.uuidString).jpg"
        let options = FileOptions(contentType: "image/jpeg", upsert: true)
        try await supabase.storage
            .from(progressPhotosBucket)
            .upload(path, data: data, options: options)

        let publicURL = try supabase.storage
            .from(progressPhotosBucket)
            .getPublicURL(path: path)

        return publicURL.absoluteString
    }

}

enum SupabaseError: Error {
    case notAuthenticated
    case networkError(String)
    case dataError(String)
}

// MARK: - Supabase Wrapper Structs

struct SupabaseWorkout: Codable {
    let id: String
    let user_id: String
    let date: String
    let name: String
    let exercises: [SupabaseExercise]
    let notes: String?
    let duration: Int?
    let body_weight: Double?
    let progress_photo_url: String?
    let created_at: String
    let updated_at: String
    
    init(from workout: Workout, userId: String) {
        self.id = workout.id.uuidString
        self.user_id = userId
        self.date = ISO8601DateFormatter().string(from: workout.date)
        self.name = workout.name
        self.exercises = workout.exercises.map { SupabaseExercise(from: $0) }
        self.notes = workout.notes
        self.duration = workout.duration.map { Int($0) }
        self.body_weight = workout.bodyWeight
        self.progress_photo_url = workout.progressPhotoURL
        self.created_at = ISO8601DateFormatter().string(from: Date())
        self.updated_at = ISO8601DateFormatter().string(from: Date())
    }
}

struct SupabaseExercise: Codable {
    let id: String
    let template_id: String
    let name: String
    let sets: [SupabaseExerciseSet]
    let max_weight: Double?
    
    init(from exercise: Exercise) {
        self.id = exercise.id.uuidString
        self.template_id = exercise.templateId.uuidString
        self.name = exercise.name
        self.sets = exercise.sets.map { SupabaseExerciseSet(from: $0) }
        self.max_weight = exercise.maxWeight
    }
}

struct SupabaseExerciseSet: Codable {
    let id: String
    let weight: Double
    let reps: Int
    
    init(from set: ExerciseSet) {
        self.id = set.id.uuidString
        self.weight = set.weight
        self.reps = set.reps
    }
}

struct SupabaseUserProfile: Codable {
    let user_id: String
    let name: String
    let email: String
    let bio: String
    let profile_image_url: String?
    let body_weight_goal: SupabaseBodyWeightGoal?
    let goals: [SupabaseExerciseGoal]
    let workout_split: [SupabaseWorkoutDay]
    let created_at: String
    let updated_at: String
    
    init(from profile: UserProfile, userId: String) {
        self.user_id = userId
        self.name = profile.name
        self.email = profile.email
        self.bio = profile.bio
        self.profile_image_url = profile.profileImageURL
        self.body_weight_goal = profile.bodyWeightGoal.map { SupabaseBodyWeightGoal(from: $0) }
        self.goals = profile.goals.map { SupabaseExerciseGoal(from: $0) }
        self.workout_split = profile.workoutSplit.map { SupabaseWorkoutDay(from: $0) }
        self.created_at = ISO8601DateFormatter().string(from: Date())
        self.updated_at = ISO8601DateFormatter().string(from: Date())
    }
}

struct SupabaseWorkoutDay: Codable {
    let id: String
    let name: String
    let exercises: [SupabaseExerciseTemplate]
    
    init(from workoutDay: UserProfile.WorkoutDay) {
        self.id = workoutDay.id.uuidString
        self.name = workoutDay.name
        self.exercises = workoutDay.exercises.map { SupabaseExerciseTemplate(from: $0) }
    }
}

struct SupabaseExerciseTemplate: Codable {
    let id: String
    let name: String
    let weight: Double?
    let reps: Int?
    
    init(from template: ExerciseTemplate) {
        self.id = template.id.uuidString
        self.name = template.name
        self.weight = template.weight
        self.reps = template.reps
    }
}

struct SupabaseExerciseGoal: Codable {
    let id: String
    let exercise_name: String
    let target_weight: Double
    let current_weight: Double
    
    init(from goal: ExerciseGoal) {
        self.id = goal.id.uuidString
        self.exercise_name = goal.exerciseName
        self.target_weight = goal.targetWeight
        self.current_weight = goal.currentWeight
    }
}

struct SupabaseBodyWeightGoal: Codable {
    let target_weight: Double
    let current_weight: Double
    let starting_weight: Double
    let start_date: String
    let target_date: String
    
    init(from goal: BodyWeightGoal) {
        self.target_weight = goal.targetWeight
        self.current_weight = goal.currentWeight
        self.starting_weight = goal.startingWeight
        self.start_date = ISO8601DateFormatter().string(from: goal.startDate)
        self.target_date = ISO8601DateFormatter().string(from: goal.targetDate)
    }
}
