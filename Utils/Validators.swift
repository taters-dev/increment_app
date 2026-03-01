import Foundation

struct Validators {
    // Validate weight input (positive number)
    static func validateWeight(_ input: String) -> Result<Double, AppError> {
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            return .failure(.validation("Weight cannot be empty"))
        }

        guard let weight = Double(trimmed), weight > 0 else {
            return .failure(.validation("Weight must be a positive number"))
        }

        guard weight <= 10000 else {
            return .failure(.validation("Weight must be less than 10,000 lbs"))
        }

        return .success(weight)
    }

    // Validate reps input (positive integer)
    static func validateReps(_ input: String) -> Result<Int, AppError> {
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            return .failure(.validation("Reps cannot be empty"))
        }

        guard let reps = Int(trimmed), reps > 0 else {
            return .failure(.validation("Reps must be a positive number"))
        }

        guard reps <= 1000 else {
            return .failure(.validation("Reps must be less than 1,000"))
        }

        return .success(reps)
    }

    // Validate comma-separated weights
    static func validateWeightString(_ input: String) -> Result<[Double], AppError> {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .failure(.validation("Please enter at least one weight value"))
        }

        let values = trimmed.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        var weights: [Double] = []
        for value in values {
            switch validateWeight(value) {
            case .success(let weight):
                weights.append(weight)
            case .failure(let error):
                return .failure(error)
            }
        }

        return .success(weights)
    }

    // Validate comma-separated reps
    static func validateRepsString(_ input: String) -> Result<[Int], AppError> {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .failure(.validation("Please enter at least one reps value"))
        }

        let values = trimmed.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        var reps: [Int] = []
        for value in values {
            switch validateReps(value) {
            case .success(let rep):
                reps.append(rep)
            case .failure(let error):
                return .failure(error)
            }
        }

        return .success(reps)
    }

    // Validate exercise name
    static func validateExerciseName(_ input: String) -> Result<String, AppError> {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .failure(.validation("Exercise name cannot be empty"))
        }

        guard trimmed.count >= 2 else {
            return .failure(.validation("Exercise name must be at least 2 characters"))
        }

        guard trimmed.count <= 50 else {
            return .failure(.validation("Exercise name must be less than 50 characters"))
        }

        return .success(trimmed)
    }

    // Validate body weight
    static func validateBodyWeight(_ input: String) -> Result<Double, AppError> {
        let trimmed = input.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            return .failure(.validation("Body weight cannot be empty"))
        }

        guard let weight = Double(trimmed), weight > 0 else {
            return .failure(.validation("Body weight must be a positive number"))
        }

        guard weight >= 50 && weight <= 1000 else {
            return .failure(.validation("Body weight must be between 50 and 1,000 lbs"))
        }

        return .success(weight)
    }
}
