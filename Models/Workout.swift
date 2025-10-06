import Foundation

struct ExerciseTemplate: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var weight: Double?
    var reps: Int?
    var weightString: String? // For comma-separated values like "225, 225, 220"
    var repsString: String?   // For comma-separated values like "7, 6, 9"
    
    static func fromSupabase(data: [String: Any]) -> ExerciseTemplate? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String else {
            return nil
        }
        
        let weight = data["weight"] as? Double
        let reps = data["reps"] as? Int
        let weightString = data["weightString"] as? String
        let repsString = data["repsString"] as? String
        
        return ExerciseTemplate(
            id: id,
            name: name,
            weight: weight,
            reps: reps,
            weightString: weightString,
            repsString: repsString
        )
    }
}

struct Exercise: Identifiable, Codable {
    var id = UUID()
    var templateId: UUID
    var name: String
    var sets: [ExerciseSet]
    var notes: String?
    var maxWeight: Double?
    
    static func fromSupabase(data: [String: Any]) -> Exercise? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String else {
            return nil
        }
        
        var sets: [ExerciseSet] = []
        if let setsData = data["sets"] as? [[String: Any]] {
            sets = setsData.compactMap { ExerciseSet.fromSupabase(data: $0) }
        }
        
        let notes = data["notes"] as? String
        let maxWeight = data["max_weight"] as? Double
        
        // Generate a templateId if not present
        let templateId = UUID()
        
        return Exercise(
            id: id,
            templateId: templateId,
            name: name,
            sets: sets,
            notes: notes,
            maxWeight: maxWeight
        )
    }
}

struct ExerciseSet: Identifiable, Codable {
    var id = UUID()
    var reps: Int
    var weight: Double
    var isCompleted: Bool = false
    
    static func fromSupabase(data: [String: Any]) -> ExerciseSet? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let reps = data["reps"] as? Int,
              let weight = data["weight"] as? Double,
              let isCompleted = data["isCompleted"] as? Bool else {
            return nil
        }
        
        return ExerciseSet(
            id: id,
            reps: reps,
            weight: weight,
            isCompleted: isCompleted
        )
    }
}

struct Workout: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var name: String
    var exercises: [Exercise]
    var notes: String?
    var duration: TimeInterval?
    var bodyWeight: Double?
    var progressPhotoData: Data?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// Extension to help with calendar view
extension Workout {
    static func workoutsForDate(_ date: Date, workouts: [Workout]) -> [Workout] {
        let calendar = Calendar.current
        return workouts.filter { workout in
            calendar.isDate(workout.date, inSameDayAs: date)
        }
    }
    
    static func datesWithWorkouts(_ workouts: [Workout]) -> Set<Date> {
        let calendar = Calendar.current
        return Set(workouts.map { calendar.startOfDay(for: $0.date) })
    }
    
    static func fromSupabase(data: [String: Any]) -> Workout? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let dateString = data["date"] as? String,
              let date = ISO8601DateFormatter().date(from: dateString),
              let name = data["name"] as? String else {
            return nil
        }
        
        var exercises: [Exercise] = []
        if let exercisesData = data["exercises"] as? [[String: Any]] {
            exercises = exercisesData.compactMap { Exercise.fromSupabase(data: $0) }
        }
        
        let notes = data["notes"] as? String
        let duration = data["duration"] as? TimeInterval
        let bodyWeight = data["body_weight"] as? Double
        let progressPhotoDataString = data["progress_photo_data"] as? String
        let progressPhotoData = progressPhotoDataString != nil ? Data(base64Encoded: progressPhotoDataString!) : nil
        
        return Workout(
            id: id,
            date: date,
            name: name,
            exercises: exercises,
            notes: notes,
            duration: duration,
            bodyWeight: bodyWeight,
            progressPhotoData: progressPhotoData
        )
    }
} 