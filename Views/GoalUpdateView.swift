import SwiftUI

struct GoalUpdateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfileStore: UserProfileStore
    @State private var showingAddExerciseGoal = false
    @State private var showingEditBodyWeightGoal = false
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Set Goals")
                    .font(.headline)
                    .padding(.top)
                
                VStack(spacing: 12) {
                    NavigationLink(destination: EditBodyWeightGoalView(isPresented: $showingEditBodyWeightGoal)) {
                        HStack {
                            Image(systemName: "scalemass.fill")
                            Text("Body Weight Goal")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    NavigationLink(destination: AddExerciseGoalView(isPresented: $showingAddExerciseGoal)) {
                        HStack {
                            Image(systemName: "dumbbell.fill")
                            Text("Exercise Goal")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width * 0.85)
            .background(Color.white)
            .cornerRadius(15)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func deleteExerciseGoal(_ goal: ExerciseGoal) {
        guard var profile = userProfileStore.profile else { return }
        profile.goals.removeAll { $0.id == goal.id }
        userProfileStore.profile = profile
        Task {
            await userProfileStore.saveProfile()
        }
    }
}

struct AddExerciseGoalView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userProfileStore: UserProfileStore
    @EnvironmentObject var workoutStore: WorkoutStore
    @Binding var isPresented: Bool
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    @State private var exerciseName = ""
    @State private var currentWeight = ""
    @State private var targetWeight = ""
    
    private var exercises: [String] {
        // Get exercises from completed workouts
        let workoutExercises = Set(workoutStore.workouts.flatMap { workout in
            workout.exercises.map { $0.name }
        })
        
        // Get exercises from workout split templates
        let templateExercises = Set(userProfileStore.profile?.workoutSplit.flatMap { workoutDay in
            workoutDay.exercises.map { $0.name }
        } ?? [])
        
        // Combine and sort
        return (workoutExercises.union(templateExercises)).sorted()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                // Exercise Name
                VStack(alignment: .leading) {
                    Text("Exercise")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack {
                        // Scrollable exercise picker
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(exercises, id: \.self) { exercise in
                                    Button(action: {
                                        exerciseName = exercise
                                        if let lastWeight = findLastWeight(for: exercise) {
                                            currentWeight = String(format: "%.1f", lastWeight)
                                        }
                                    }) {
                                        HStack {
                                            Text(exercise)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if exerciseName == exercise {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.accentColor)
                                            }
                                        }
                                        .padding()
                                        .background(exerciseName == exercise ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .frame(maxHeight: 200)
                        
                        // Custom exercise input
                        HStack {
                            TextField("Or enter custom exercise", text: $exerciseName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            if !exerciseName.isEmpty && !exercises.contains(exerciseName) {
                                Button("Add") {
                                    // Custom exercise will be automatically included in the list
                                }
                                .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
                
                // Current Weight
                VStack(alignment: .leading) {
                    Text("Current Weight")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("Enter Weight", text: $currentWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 28, weight: .medium))
                            .frame(maxWidth: .infinity)
                        
                        Text("lbs")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                // Target Weight
                VStack(alignment: .leading) {
                    Text("Target Weight")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("Enter Target", text: $targetWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 28, weight: .medium))
                            .frame(maxWidth: .infinity)
                        
                        Text("lbs")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                if !exercises.isEmpty {
                    Text("Can't find your exercise? Add a custom one below.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Custom Exercise Name", text: $exerciseName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            HStack {
                Spacer()
                
                Button("Save") {
                    saveExerciseGoal()
                    isPresented = false
                }
                .disabled(exerciseName.isEmpty || currentWeight.isEmpty || targetWeight.isEmpty)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: UIScreen.main.bounds.width * 0.85)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .navigationTitle("Exercise Goal")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    isPresented = false
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
        }
    }
    
    private func findLastWeight(for exercise: String) -> Double? {
        workoutStore.workouts
            .flatMap { $0.exercises }
            .filter { $0.name == exercise }
            .compactMap { exercise in
                exercise.sets.map { $0.weight }.max()
            }
            .max()
    }
    
    private func saveExerciseGoal() {
        // saveExerciseGoal called
        
        guard let current = Double(currentWeight),
              let target = Double(targetWeight) else { 
            // Invalid weight values
            return 
        }
        
        let goal = ExerciseGoal(
            exerciseName: exerciseName,
            targetWeight: target,
            currentWeight: current
        )
        
        // Created goal
        
        var profile = userProfileStore.profile ?? UserProfile(
            name: "",
            email: "",
            bio: "",
            workoutSplit: [],
            goals: []
        )
        
        // Current profile has goals
        
        // Update existing goal if it exists
        if let index = profile.goals.firstIndex(where: { $0.exerciseName == exerciseName }) {
            profile.goals[index] = goal
            // Updated existing goal at index
        } else {
            profile.goals.append(goal)
            // Added new goal
        }
        
        userProfileStore.profile = profile
        // Set profile in store
        Task {
            await userProfileStore.saveProfile()
        }
        presentationMode.wrappedValue.dismiss()
    }
}

struct EditBodyWeightGoalView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userProfileStore: UserProfileStore
    @EnvironmentObject var workoutStore: WorkoutStore
    @Binding var isPresented: Bool
    let initialGoal: BodyWeightGoal?
    
    @State private var currentWeight = ""
    @State private var targetWeight = ""
    @State private var targetDate = Date()
    
    init(isPresented: Binding<Bool>, initialGoal: BodyWeightGoal? = nil) {
        self._isPresented = isPresented
        self.initialGoal = initialGoal
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private var lastRecordedWeight: Double? {
        workoutStore.workouts
            .compactMap { $0.bodyWeight }
            .last
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Body Weight Goal")
                .font(.headline)
                .padding(.top)
            
            VStack(spacing: 12) {
                // Current Weight
                VStack(alignment: .leading) {
                    Text("Current Weight")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("Enter Weight", text: $currentWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 28, weight: .medium))
                            .frame(maxWidth: .infinity)
                        
                        Text("lbs")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    if let lastWeight = lastRecordedWeight {
                        Text("Last recorded: \(String(format: "%.1f", lastWeight)) lbs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Target Weight
                VStack(alignment: .leading) {
                    Text("Target Weight")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("Enter Target", text: $targetWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 28, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        hideKeyboard()
                                    }
                                }
                            }
                        
                        Text("lbs")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                
                // Target Date
                VStack(alignment: .leading) {
                    Text("Target Date")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $targetDate, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Save") {
                    saveBodyWeightGoal()
                    isPresented = false
                }
                .disabled(currentWeight.isEmpty || targetWeight.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: UIScreen.main.bounds.width * 0.85)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .navigationTitle("Body Weight Goal")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let goal = userProfileStore.profile?.bodyWeightGoal {
                currentWeight = String(format: "%.1f", goal.currentWeight)
                targetWeight = String(format: "%.1f", goal.targetWeight)
                targetDate = goal.targetDate
            } else if let lastWeight = lastRecordedWeight {
                currentWeight = String(format: "%.1f", lastWeight)
            }
        }
    }
    
    private func saveBodyWeightGoal() {
        // saveBodyWeightGoal called
        
        guard let current = Double(currentWeight),
              let target = Double(targetWeight) else { 
            // Invalid weight values
            return 
        }
        
        let goal = BodyWeightGoal(
            targetWeight: target,
            currentWeight: current,
            startingWeight: current,
            startDate: Date(),
            targetDate: targetDate
        )
        
        // Created body weight goal
        
        var profile = userProfileStore.profile ?? UserProfile(
            name: "",
            email: "",
            bio: "",
            workoutSplit: [],
            goals: []
        )
        profile.bodyWeightGoal = goal
        // Set body weight goal in profile
        userProfileStore.profile = profile
        // Set profile in store
        
        // Find or create a weight tracking entry for today
        let today = Calendar.current.startOfDay(for: Date())
        
        // Check if a "Weight Update" workout already exists for today
        if let existingIndex = workoutStore.workouts.firstIndex(where: { workout in
            Calendar.current.isDate(workout.date, inSameDayAs: today) && workout.name == "Weight Update"
        }) {
            // Update existing workout
            workoutStore.workouts[existingIndex].bodyWeight = current
            // Updated existing weight workout for today
        } else {
            // Create new workout
            let workout = Workout(
                date: Date(),
                name: "Weight Update",
                exercises: [],
                bodyWeight: current
            )
            workoutStore.workouts.append(workout)
            // Created new weight workout for today
        }
        
        Task {
            await workoutStore.saveWorkouts()
            await userProfileStore.saveProfile()
        }
        presentationMode.wrappedValue.dismiss()
    }
}

struct EditExerciseGoalView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userProfileStore: UserProfileStore
    @Binding var isPresented: Bool
    let initialGoal: ExerciseGoal
    
    @State private var exerciseName = ""
    @State private var currentWeight = ""
    @State private var targetWeight = ""
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Exercise Goal")
                .font(.headline)
                .padding(.top)
            
            VStack(spacing: 12) {
                // Exercise Name (read-only)
                VStack(alignment: .leading) {
                    Text("Exercise")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("Exercise Name", text: $exerciseName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(true)
                }
                
                // Current Weight
                VStack(alignment: .leading) {
                    Text("Current Weight")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("Enter Weight", text: $currentWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 28, weight: .medium))
                            .frame(maxWidth: .infinity)
                        
                        Text("lbs")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Target Weight
                VStack(alignment: .leading) {
                    Text("Target Weight")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("Enter Target", text: $targetWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 28, weight: .medium))
                            .frame(maxWidth: .infinity)
                        
                        Text("lbs")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Save Button
                Button("Save Goal") {
                    saveExerciseGoal()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(currentWeight.isEmpty || targetWeight.isEmpty)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width * 0.85)
        .background(Color.white)
        .cornerRadius(15)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
        }
        .onAppear {
            exerciseName = initialGoal.exerciseName
            currentWeight = String(format: "%.1f", initialGoal.currentWeight)
            targetWeight = String(format: "%.1f", initialGoal.targetWeight)
        }
    }
    
    private func saveExerciseGoal() {
        // saveExerciseGoal called
        
        guard let current = Double(currentWeight),
              let target = Double(targetWeight) else { 
            // Invalid weight values
            return 
        }
        
        let updatedGoal = ExerciseGoal(
            id: initialGoal.id,
            exerciseName: exerciseName,
            targetWeight: target,
            currentWeight: current
        )
        
        // Created updated goal
        
        var profile = userProfileStore.profile ?? UserProfile(
            name: "",
            email: "",
            bio: "",
            workoutSplit: [],
            goals: []
        )
        
        // Current profile has goals
        
        // Update existing goal
        if let index = profile.goals.firstIndex(where: { $0.id == initialGoal.id }) {
            profile.goals[index] = updatedGoal
            // Updated existing goal at index
        } else {
            profile.goals.append(updatedGoal)
            // Added new goal
        }
        
        userProfileStore.profile = profile
        // Set profile in store
        Task {
            await userProfileStore.saveProfile()
        }
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        GoalUpdateView(onDismiss: {})
            .environmentObject(UserProfileStore())
            .environmentObject(WorkoutStore())
    }
} 