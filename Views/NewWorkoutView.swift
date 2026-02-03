import SwiftUI

struct ExerciseRow: View {
    let exercise: Exercise
    @Binding var weightText: String
    @Binding var repsText: String
    let onValuesChanged: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            // Exercise name
            Text(exercise.name)
                .font(.headline)
                .foregroundColor(.black)
                .frame(width: 120, alignment: .leading)
            
            // Weight column
            VStack(alignment: .leading, spacing: 4) {
                Text("Weight (lbs)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("225, 225, 220", text: $weightText)
                    .keyboardType(.numbersAndPunctuation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: weightText) { _, _ in
                        onValuesChanged()
                    }
            }
            
            // Reps column
            VStack(alignment: .leading, spacing: 4) {
                Text("Reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("7, 6, 9", text: $repsText)
                    .keyboardType(.numbersAndPunctuation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: repsText) { _, _ in
                        onValuesChanged()
                    }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct NewWorkoutView: View {
    @ObservedObject var workoutStore: WorkoutStore
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfileStore: UserProfileStore
    @EnvironmentObject var appStateManager: AppStateManager
    
    let presetWorkout: UserProfile.WorkoutDay?
    let existingWorkout: Workout?
    let onDismiss: () -> Void
    
    @State private var workoutName: String = ""
    @State private var exercises: [Exercise] = []
    @State private var showingAddExercise = false
    @State private var startTime: Date?
    @State private var workoutId: UUID? = nil
    
    // Text representations for comma-separated values
    @State private var exerciseTexts: [UUID: (weight: String, reps: String)] = [:]
    
    var defaultWorkout: UserProfile.WorkoutDay? {
        if let preset = presetWorkout {
            return preset
        }
        let weekday = Calendar.current.component(.weekday, from: Date()) - 1
        return userProfileStore.profile?.workoutSplit.indices.contains(weekday) ?? false
            ? userProfileStore.profile?.workoutSplit[weekday]
            : userProfileStore.profile?.workoutSplit.first
    }
    
    init(workoutStore: WorkoutStore, presetWorkout: UserProfile.WorkoutDay?, existingWorkout: Workout? = nil, onDismiss: @escaping () -> Void) {
        self.workoutStore = workoutStore
        self.presetWorkout = presetWorkout
        self.existingWorkout = existingWorkout
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            GeometryReader { geometry in
                VStack(spacing: 8) {
                    VStack(spacing: 4) {
                        Text("New Workout")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Tap exercises to expand • Add multiple sets per exercise")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                    
                    VStack(spacing: 16) {
                        // Table header
                        HStack(spacing: 20) {
                            Text("Exercise")
                                .font(.headline)
                                .frame(width: 120, alignment: .leading)
                            Text("Weight (lbs)")
                                .font(.headline)
                            Text("Reps")
                                .font(.headline)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                        
                        // Exercise rows
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(exercises.indices, id: \.self) { index in
                                    ExerciseRow(
                                        exercise: exercises[index],
                                        weightText: Binding(
                                            get: { exerciseTexts[exercises[index].id]?.weight ?? "" },
                                            set: { newValue in
                                                exerciseTexts[exercises[index].id]?.weight = newValue
                                                updateExerciseSets(from: exercises[index].id)
                                            }
                                        ),
                                        repsText: Binding(
                                            get: { exerciseTexts[exercises[index].id]?.reps ?? "" },
                                            set: { newValue in
                                                exerciseTexts[exercises[index].id]?.reps = newValue
                                                updateExerciseSets(from: exercises[index].id)
                                            }
                                        ),
                                        onValuesChanged: {
                                            saveWorkout()
                                        }
                                    )
                                }
                                
                                Button(action: { showingAddExercise = true }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Exercise")
                                    }
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                }
                                .padding(.top, 8)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            onDismiss()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        Button("Save") {
                            saveWorkout()
                            onDismiss()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            (workoutName.isEmpty || exercises.isEmpty) ?
                                Color.gray.opacity(0.5) :
                                Color("AccentColor")
                        )
                        .cornerRadius(8)
                        .disabled(workoutName.isEmpty || exercises.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .frame(width: UIScreen.main.bounds.width * 0.85)
                .frame(maxHeight: geometry.size.height * 0.5)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView { template in
                let exercise = Exercise(
                    templateId: template.id,
                    name: template.name,
                    sets: [ExerciseSet(reps: 0, weight: 0)] // Start with one set
                )
                exercises.append(exercise)
                // Initialize text fields for new exercise
                exerciseTexts[exercise.id] = (weight: "0", reps: "0")
                saveWorkout()
            }
        }
        .onAppear {            // ALWAYS prioritize the active workout from the store, regardless of parameters
            if let activeWorkout = workoutStore.activeWorkout {
                workoutName = activeWorkout.name
                exercises = activeWorkout.exercises
                startTime = activeWorkout.date
                workoutId = activeWorkout.id
                initializeTextsFromExercises()
            } else if let existingWorkout = existingWorkout {
                // Fallback to existingWorkout parameter
                workoutName = existingWorkout.name
                exercises = existingWorkout.exercises
                startTime = existingWorkout.date
                workoutId = existingWorkout.id
                initializeTextsFromExercises()
            } else if let workout = defaultWorkout {
                workoutName = workout.name
                exercises = workout.exercises.map { template in
                    Exercise(
                        templateId: template.id,
                        name: template.name,
                        sets: [ExerciseSet(reps: 0, weight: 0)] // Start each exercise with one set
                    )
                }
                startWorkout()
                initializeTextsFromExercises()            }        }
    }
    
    // Convert ExerciseSet array to comma-separated strings
    private func initializeTextsFromExercises() {
        for exercise in exercises {
            let weightString = exercise.sets.map { String(format: "%.0f", $0.weight) }.joined(separator: ", ")
            let repsString = exercise.sets.map { String($0.reps) }.joined(separator: ", ")
            exerciseTexts[exercise.id] = (weight: weightString, reps: repsString)
        }
    }
    
    // Convert comma-separated strings back to ExerciseSet array
    private func updateExerciseSets(from exerciseId: UUID) {
        guard let texts = exerciseTexts[exerciseId],
              let exerciseIndex = exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        
        let weightValues = texts.weight.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        let repsValues = texts.reps.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        
        // Create sets from the values
        var newSets: [ExerciseSet] = []
        let maxCount = max(weightValues.count, repsValues.count)
        
        for i in 0..<maxCount {
            let weight = i < weightValues.count ? weightValues[i] : 0.0
            let reps = i < repsValues.count ? repsValues[i] : 0
            newSets.append(ExerciseSet(reps: reps, weight: weight))
        }
        
        exercises[exerciseIndex].sets = newSets        // Auto-save the workout when exercise data is updated
        autoSaveWorkout()
    }
    
    private func startWorkout() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Check if a workout with this name already exists for today
        if let existingIndex = workoutStore.workouts.firstIndex(where: { workout in
            Calendar.current.isDate(workout.date, inSameDayAs: today) && workout.name == workoutName
        }) {
            // Update existing workout
            let existingWorkout = workoutStore.workouts[existingIndex]
            workoutId = existingWorkout.id
            let updatedWorkout = Workout(
                id: existingWorkout.id,
                date: startTime ?? Date(),
                name: workoutName,
                exercises: exercises
            )
            workoutStore.workouts[existingIndex] = updatedWorkout
            workoutStore.updateActiveWorkout(updatedWorkout)        } else {
            // Create new workout
            let workout = Workout(
                id: workoutId ?? UUID(),
                date: startTime ?? Date(),
                name: workoutName,
                exercises: exercises
            )
            workoutId = workout.id
            workoutStore.updateActiveWorkout(workout)
            workoutStore.workouts.append(workout)        }
        
        Task {
            await workoutStore.saveWorkouts()
        }
    }
    
    private func saveWorkout() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Check if a workout with this name already exists for today
        if let existingIndex = workoutStore.workouts.firstIndex(where: { workout in
            Calendar.current.isDate(workout.date, inSameDayAs: today) && workout.name == workoutName
        }) {
            // Update existing workout
            let existingWorkout = workoutStore.workouts[existingIndex]
            let updatedWorkout = Workout(
                id: existingWorkout.id,
                date: startTime ?? Date(),
                name: workoutName,
                exercises: exercises
            )
            workoutStore.workouts[existingIndex] = updatedWorkout
            workoutStore.updateActiveWorkout(updatedWorkout)        } else {
            // Create new workout
            let updatedWorkout = Workout(
                id: workoutId ?? UUID(),
                date: startTime ?? Date(),
                name: workoutName,
                exercises: exercises
            )
            workoutStore.workouts.append(updatedWorkout)
            workoutStore.updateActiveWorkout(updatedWorkout)        }
        
        for exercise in exercises {        }
        
        Task {
            await workoutStore.saveWorkouts()
        }
    }
    
    private func autoSaveWorkout() {
        // Create a temporary workout with current exercise data
        let tempWorkout = Workout(
            id: workoutId ?? UUID(),
            date: startTime ?? Date(),
            name: workoutName,
            exercises: exercises
        )
        
        // Update the active workout in the store
        workoutStore.updateActiveWorkout(tempWorkout)
        
        // Also save the complete app state
        appStateManager.saveCurrentState(
            workoutStore: workoutStore,
            userProfileStore: userProfileStore,
            selectedWorkoutDay: presetWorkout
        )    }
}

#Preview {
    NewWorkoutView(
        workoutStore: WorkoutStore(),
        presetWorkout: UserProfile.WorkoutDay(
            name: "Sample Workout",
            exercises: [
                ExerciseTemplate(name: "Bench Press")
            ]
        ),
        onDismiss: {}
    )
} 
