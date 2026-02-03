import SwiftUI

struct HomeView: View {
    @EnvironmentObject var workoutStore: WorkoutStore
    @EnvironmentObject var userProfileStore: UserProfileStore
    @EnvironmentObject var appStateManager: AppStateManager
    @State private var showingNewWorkout = false
    @State private var showingProgressPhotoUpload = false
    @State private var showingWeightUpdate = false
    @State private var showingGoalUpdate = false
    @State private var selectedImage: UIImage?
    @State private var bodyWeight: String = ""
    @State private var selectedWorkout: Workout?
    @State private var showingWorkoutDetail = false
    @State private var selectedWorkoutDay: UserProfile.WorkoutDay?
    @State private var showingWorkoutPicker = false
    @State private var showingSettings = false
    @State private var showingExerciseEditor = false
    @State private var showingExerciseHistory = false
    @State private var selectedExerciseForHistory: String = ""
    
    var todayWorkout: UserProfile.WorkoutDay? {
        let weekday = Calendar.current.component(.weekday, from: Date()) - 1
        return userProfileStore.profile?.workoutSplit.indices.contains(weekday) ?? false
            ? userProfileStore.profile?.workoutSplit[weekday]
            : nil
    }
    
    var todaysWorkouts: [Workout] {
        let calendar = Calendar.current
        return workoutStore.workouts.filter { workout in
            calendar.isDate(workout.date, inSameDayAs: Date())
        }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                // App title at the top - pinned
                VStack(spacing: 8) {
                    Text("INCREMENT")
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .italic()
                        .foregroundColor(Color(red: 11/255, green: 20/255, blue: 64/255))
                    
                    Text(Date(), style: .date)
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 10)
                .padding(.top, 20)
                .background(Color.white)
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 16) {
                        // Today's Workout Modal
                        if let profile = userProfileStore.profile {
                            if let workout = todayWorkout {
                                TodayWorkoutCard(
                                    workout: workout,
                                    workoutSplit: profile.workoutSplit,
                                    selectedWorkout: $selectedWorkoutDay,
                                    showingWorkoutPicker: $showingWorkoutPicker,
                                    showingSettings: $showingSettings,
                                    showingExerciseEditor: $showingExerciseEditor,
                                    showingExerciseHistory: $showingExerciseHistory,
                                    selectedExerciseForHistory: $selectedExerciseForHistory,
                                    onStartTap: { 
                                        // Capture the selected workout when starting
                                        if let activeWorkout = workoutStore.activeWorkout {
                                            // Starting workout with active workout
                                        } else {
                                            // Starting workout with no active workout
                                        }
                                        showingNewWorkout = true 
                                    },
                                    onWorkoutPickerTap: { showingWorkoutPicker.toggle() }
                                )
                                .environmentObject(userProfileStore)
                                .padding(.horizontal, 16)
                            } else if !profile.workoutSplit.isEmpty {
                                TodayWorkoutCard(
                                    workout: profile.workoutSplit[0],
                                    workoutSplit: profile.workoutSplit,
                                    selectedWorkout: $selectedWorkoutDay,
                                    showingWorkoutPicker: $showingWorkoutPicker,
                                    showingSettings: $showingSettings,
                                    showingExerciseEditor: $showingExerciseEditor,
                                    showingExerciseHistory: $showingExerciseHistory,
                                    selectedExerciseForHistory: $selectedExerciseForHistory,
                                    onStartTap: { 
                                        // Capture the selected workout when starting
                                        if let activeWorkout = workoutStore.activeWorkout {
                                            // Starting workout with active workout
                                        } else {
                                            // Starting workout with no active workout
                                        }
                                        showingNewWorkout = true 
                                    },
                                    onWorkoutPickerTap: { showingWorkoutPicker.toggle() }
                                )
                                .environmentObject(userProfileStore)
                                .padding(.horizontal, 16)
                            } else {
                                NoWorkoutScheduledCard()
                                    .padding(.horizontal, 16)
                            }
                        } else {
                            NoWorkoutScheduledCard()
                                .padding(.horizontal, 16)
                        }
                        
                        // Quick Actions
                        QuickActionsGrid(
                            onProgressPhotoTap: { showingProgressPhotoUpload = true },
                            onWeightUpdateTap: { showingWeightUpdate = true },
                            onGoalUpdateTap: { showingGoalUpdate = true }
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 10)
                }
            }
        }
        .sheet(isPresented: $showingNewWorkout) {
            // Always use the active workout if it exists, regardless of name matching
            let selectedDay = selectedWorkoutDay ?? todayWorkout
            let activeWorkout = workoutStore.activeWorkout
            
            if let activeWorkout = activeWorkout {
                // Use the existing active workout (prioritize active workout over name matching)
                NewWorkoutView(
                    workoutStore: workoutStore,
                    presetWorkout: selectedDay,
                    existingWorkout: activeWorkout,
                    onDismiss: { 
                        showingNewWorkout = false
                    }
                )
            } else {
                // Start fresh workout
                NewWorkoutView(
                    workoutStore: workoutStore,
                    presetWorkout: selectedDay,
                    onDismiss: { 
                        showingNewWorkout = false
                    }
                )
            }
        }
        .onChange(of: showingNewWorkout) { isShowing in
            if isShowing {
                let selectedDay = selectedWorkoutDay ?? todayWorkout
                let activeWorkout = workoutStore.activeWorkout
                // Opening NewWorkoutView
            }
        }
        .onChange(of: selectedWorkoutDay) { newSelectedDay in
            // Save state when workout day selection changes
            appStateManager.saveCurrentState(
                workoutStore: workoutStore,
                userProfileStore: userProfileStore,
                selectedWorkoutDay: newSelectedDay
            )
        }
        .sheet(isPresented: $showingProgressPhotoUpload) {
            ProgressPhotoUploadView(
                selectedImage: $selectedImage,
                onDismiss: { showingProgressPhotoUpload = false }
            )
            .environmentObject(workoutStore)
        }
        .sheet(isPresented: $showingWeightUpdate) {
            WeightUpdateView(
                bodyWeight: $bodyWeight,
                onDismiss: { showingWeightUpdate = false }
            )
            .environmentObject(workoutStore)
            .environmentObject(userProfileStore)
        }
        .sheet(isPresented: $showingGoalUpdate) {
            GoalUpdateView(
                onDismiss: { showingGoalUpdate = false }
            )
            .environmentObject(userProfileStore)
        }
        .sheet(isPresented: $showingWorkoutDetail) {
            if let workout = selectedWorkout {
                WorkoutDetailView(workout: workout)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(userProfileStore)
        }
        .sheet(isPresented: $showingExerciseEditor) {
            ExerciseEditorView(
                workoutDay: selectedWorkoutDay ?? todayWorkout,
                onDismiss: { 
                    showingExerciseEditor = false
                }
            )
            .environmentObject(userProfileStore)
        }
        .sheet(isPresented: $showingExerciseHistory) {
            ExerciseHistoryView(exerciseName: selectedExerciseForHistory)
                .environmentObject(workoutStore)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}



struct TodayWorkoutCard: View {
    let workout: UserProfile.WorkoutDay
    let onStartTap: () -> Void
    let workoutSplit: [UserProfile.WorkoutDay]
    let onWorkoutPickerTap: () -> Void
    @Binding var selectedWorkout: UserProfile.WorkoutDay?
    @Binding var showingWorkoutPicker: Bool
    @Binding var showingSettings: Bool
    @Binding var showingExerciseEditor: Bool
    @Binding var showingExerciseHistory: Bool
    @Binding var selectedExerciseForHistory: String
    @EnvironmentObject var workoutStore: WorkoutStore
    @EnvironmentObject var userProfileStore: UserProfileStore
    @State private var editedExercises: [ExerciseTemplate] = []
    @State private var showingExerciseNamePrompt = false
    @State private var newExerciseName = ""
    
    init(
        workout: UserProfile.WorkoutDay,
        workoutSplit: [UserProfile.WorkoutDay],
        selectedWorkout: Binding<UserProfile.WorkoutDay?>,
        showingWorkoutPicker: Binding<Bool>,
        showingSettings: Binding<Bool>,
        showingExerciseEditor: Binding<Bool>,
        showingExerciseHistory: Binding<Bool>,
        selectedExerciseForHistory: Binding<String>,
        onStartTap: @escaping () -> Void,
        onWorkoutPickerTap: @escaping () -> Void
    ) {
        self.workout = workout
        self.workoutSplit = workoutSplit
        self.onStartTap = onStartTap
        self.onWorkoutPickerTap = onWorkoutPickerTap
        _selectedWorkout = selectedWorkout
        _showingWorkoutPicker = showingWorkoutPicker
        _showingSettings = showingSettings
        _showingExerciseEditor = showingExerciseEditor
        _showingExerciseHistory = showingExerciseHistory
        _selectedExerciseForHistory = selectedExerciseForHistory
    }
    
    var displayedWorkout: UserProfile.WorkoutDay {
        return selectedWorkout ?? workout
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with workout name, logo, and edit button
            HStack {
                Text("Today's Workout: \(displayedWorkout.name)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    
                    Image("increment_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 50)
                }
            }
            
            // Exercises section - now with inline editing
            VStack(alignment: .leading, spacing: 16) {

                
                if !displayedWorkout.exercises.isEmpty {
                    // Spreadsheet-like exercise list
                    VStack(spacing: 0) {
                        // Header row
                        HStack {
                            Text("Exercise")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: addExercise) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Color("AccentColor"))
                                    .font(.title2)
                            }
                            .frame(width: 30)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        
                        // Exercise rows with comma-separated values
                        List {
                            ForEach(editedExercises) { exercise in
                                ExerciseRowView(
                                    exercise: exercise,
                                    editedExercises: $editedExercises,
                                    onSave: saveChanges,
                                    onExerciseNameTap: { exerciseName in
                                        selectedExerciseForHistory = exerciseName
                                        showingExerciseHistory = true
                                    }
                                )
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: removeExercise)
                        }
                        .listStyle(PlainListStyle())
                        .frame(height: max(CGFloat(editedExercises.count * 60), 240)) // Minimum height for 4 rows
                        
                        
                        // Fallback if no exercises are loaded
                        if editedExercises.isEmpty {
                            VStack(spacing: 12) {
                                Text("No exercises for this workout")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Button(action: { 
                                    // Add first exercise directly to the table
                                    addExercise()
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add First Exercise")
                                    }
                                    .font(.headline)
                                    .foregroundColor(Color("AccentColor"))
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 24)
                                    .background(Color("AccentColor").opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                            .padding()
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                } else {
                    // No exercises placeholder
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("No exercises added yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button(action: addExercise) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add First Exercise")
                            }
                            .font(.headline)
                            .foregroundColor(Color("AccentColor"))
                            .padding(.vertical, 16)
                            .padding(.horizontal, 24)
                            .background(Color("AccentColor").opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(32)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            
            // Workout Picker (within the modal)
            if showingWorkoutPicker, workoutSplit.count > 1 {
                VStack(spacing: 12) {
                    ForEach(workoutSplit) { workoutDay in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedWorkout = workoutDay
                                showingWorkoutPicker = false
                            }
                        }) {
                            HStack {
                                Text(workoutDay.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedWorkout?.id == workoutDay.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color("AccentColor"))
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: showingWorkoutPicker)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                if workoutSplit.count > 1 {
                    Button(action: onWorkoutPickerTap) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Switch Workout")
                        }
                        .font(.headline)
                        .foregroundColor(Color("AccentColor"))
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .background(Color("AccentColor").opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding(24)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
        .onAppear {
            // Check if there's an active workout for today and use that data
            let today = Calendar.current.startOfDay(for: Date())
            if let activeWorkout = workoutStore.activeWorkout,
               Calendar.current.isDate(activeWorkout.date, inSameDayAs: today),
               activeWorkout.name == displayedWorkout.name {
                // Convert Exercise to ExerciseTemplate for display
                editedExercises = activeWorkout.exercises.map { exercise in
                    // Convert all sets to comma-separated strings
                    let weightString = exercise.sets.map { $0.weight.description }.joined(separator: ", ")
                    let repsString = exercise.sets.map { $0.reps.description }.joined(separator: ", ")
                    
                    return ExerciseTemplate(
                        id: exercise.templateId,
                        name: exercise.name,
                        weightString: weightString.isEmpty ? "0" : weightString,
                        repsString: repsString.isEmpty ? "0" : repsString
                    )
                }
                // Loaded active workout data
            } else {
                // Fallback to workout split exercises
                editedExercises = displayedWorkout.exercises
                // Loaded workout split exercises
            }
        }
        .onChange(of: selectedWorkout) { newWorkout in
            // Check if there's an active workout for today and use that data
            let today = Calendar.current.startOfDay(for: Date())
            if let activeWorkout = workoutStore.activeWorkout,
               Calendar.current.isDate(activeWorkout.date, inSameDayAs: today),
               activeWorkout.name == displayedWorkout.name {
                // Convert Exercise to ExerciseTemplate for display
                editedExercises = activeWorkout.exercises.map { exercise in
                    // Convert all sets to comma-separated strings
                    let weightString = exercise.sets.map { $0.weight.description }.joined(separator: ", ")
                    let repsString = exercise.sets.map { $0.reps.description }.joined(separator: ", ")
                    
                    return ExerciseTemplate(
                        id: exercise.templateId,
                        name: exercise.name,
                        weightString: weightString.isEmpty ? "0" : weightString,
                        repsString: repsString.isEmpty ? "0" : repsString
                    )
                }
                // Changed to active workout data
            } else {
                // Fallback to workout split exercises
                editedExercises = displayedWorkout.exercises
                // Changed to workout split exercises
            }
        }
        .alert("Add Exercise", isPresented: $showingExerciseNamePrompt) {
            TextField("Exercise Name", text: $newExerciseName)
            Button("Add") {
                addExerciseWithName()
            }
            .disabled(newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("Cancel", role: .cancel) {
                showingExerciseNamePrompt = false
            }
        } message: {
            Text("Enter a name for the new exercise.")
        }
    }
    
    private func addExercise() {
        newExerciseName = ""
        showingExerciseNamePrompt = true
    }
    
    private func addExerciseWithName() {
        guard !newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newExercise = ExerciseTemplate(
            name: newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines), 
            weight: 0.0, 
            reps: 0, 
            weightString: "", 
            repsString: ""
        )
        editedExercises.append(newExercise)
        // Save the changes to persist the new exercise
        saveChanges()
        showingExerciseNamePrompt = false
    }
    
    private func removeExercise(at offsets: IndexSet) {
        editedExercises.remove(atOffsets: offsets)
        // Save the changes to persist the deletion
        saveChanges()
    }
    
    private func refreshExercises() {
        editedExercises = displayedWorkout.exercises
    }
    
    private func saveChanges() {
        // Only create a workout entry for the current day - DO NOT modify workout split templates
        // The workout split templates should remain unchanged when editing today's workout
        createWorkoutEntry()
        // Saved changes to current day's workout only
    }
    
    private func parseSetsFromStrings(weightsString: String, repsString: String) -> [ExerciseSet] {
        // Split comma-separated values
        let weightValues = weightsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let repValues = repsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        var sets: [ExerciseSet] = []
        let maxCount = max(weightValues.count, repValues.count)
        
        for i in 0..<maxCount {
            let weightString = i < weightValues.count ? weightValues[i] : ""
            let repString = i < repValues.count ? repValues[i] : ""
            
            // Parse weight (default to 0 if empty or invalid)
            let weight = Double(weightString) ?? 0.0
            
            // Parse reps (default to 0 if empty or invalid)
            let reps = Int(repString) ?? 0
            
            // Create set if we have any data (including 0 values for tracking purposes)
            if !weightString.isEmpty || !repString.isEmpty {
                let set = ExerciseSet(
                    reps: reps,
                    weight: weight
                )
                sets.append(set)
            }
        }
        
        return sets
    }
    
    private func createWorkoutEntry() {
        // Convert ExerciseTemplates to Exercises for the workout entry
        let exercises = editedExercises.compactMap { template -> Exercise? in
            // Only create exercise if it has a name and actual data
            guard !template.name.isEmpty && (!template.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) else {
                return nil
            }
            
            // Parse comma-separated values into individual sets
            let sets = parseSetsFromStrings(
                weightsString: template.weightString ?? "",
                repsString: template.repsString ?? ""
            )
            
            // Auto-calculate max weight from the sets
            let maxWeight = sets.map { $0.weight }.max()
            
            return Exercise(
                templateId: template.id,
                name: template.name.isEmpty ? "Exercise" : template.name,
                sets: sets,
                maxWeight: maxWeight
            )
        }
        
        // Always update the workout entry, even if empty (to persist deletions)
        
        if exercises.isEmpty {
            // Remove the workout entry if no exercises
            workoutStore.workouts.removeAll { workout in
                Calendar.current.isDate(workout.date, inSameDayAs: Date()) && workout.name == displayedWorkout.name
            }
            // Also clear the active workout if it matches
            if workoutStore.activeWorkout?.name == displayedWorkout.name {
                workoutStore.activeWorkout = nil
                // Cleared active workout (no exercises)
            }
        } else {
            // Find existing workout for today to preserve its ID
            let existingWorkout = workoutStore.workouts.first(where: { 
                Calendar.current.isDate($0.date, inSameDayAs: Date()) && $0.name == displayedWorkout.name 
            })
            
            // Create workout entry for today (preserve existing ID if available)
            let workout = Workout(
                id: existingWorkout?.id ?? UUID(), // Preserve existing ID or create new one
                date: Date(),
                name: displayedWorkout.name,
                exercises: exercises,
                notes: "Workout completed",
                duration: nil,
                bodyWeight: nil
            )
            
            // Add to workout store
            if let existingIndex = workoutStore.workouts.firstIndex(where: { 
                Calendar.current.isDate($0.date, inSameDayAs: Date()) && $0.name == displayedWorkout.name 
            }) {
                // Update existing workout for today (same ID, updated data)
                workoutStore.workouts[existingIndex] = workout
                // Also update the active workout if it matches
                if workoutStore.activeWorkout?.name == displayedWorkout.name {
                    workoutStore.activeWorkout = workout
                    // Updated existing workout with same ID
                }
            } else {
                // Add new workout for today
                workoutStore.workouts.append(workout)
                // Also set as active workout if it matches today's workout
                if displayedWorkout.name == displayedWorkout.name {
                    workoutStore.activeWorkout = workout
                    // Set new workout as active workout
                }
            }
        }
        
        // Save workout store
        Task {
            await workoutStore.saveWorkouts()
        }
    }
    
}

struct NoWorkoutScheduledCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("No Workout Scheduled")
                .font(.headline)
            Text("Rest day! Take time to recover and prepare for your next workout.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title)
                    .foregroundColor(Color("AccentColor"))
                Text(title)
                    .font(.caption)
                    .bold()
                    .foregroundColor(Color("AccentColor"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .frame(height: 120)
    }
}

struct QuickActionsGrid: View {
    let onProgressPhotoTap: () -> Void
    let onWeightUpdateTap: () -> Void
    let onGoalUpdateTap: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            QuickActionButton(
                title: "Progress Photo",
                systemImage: "camera.fill",
                action: onProgressPhotoTap
            )
            QuickActionButton(
                title: "Update Weight",
                systemImage: "scalemass.fill",
                action: onWeightUpdateTap
            )
            QuickActionButton(
                title: "Update Goals",
                systemImage: "target",
                action: onGoalUpdateTap
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

struct ExerciseRowView: View {
    let exercise: ExerciseTemplate
    @Binding var editedExercises: [ExerciseTemplate]
    let onSave: () -> Void
    let onExerciseNameTap: (String) -> Void
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isRepsFocused: Bool
    @State private var saveTask: Task<Void, Never>?
    
    private var index: Int? {
        editedExercises.firstIndex(where: { $0.id == exercise.id })
    }
    
    private func delayedSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            if !Task.isCancelled {
                await MainActor.run {
                    onSave()
                }
            }
        }
    }
    
    private func immediateSave() {
        saveTask?.cancel()
        onSave()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                // Exercise name - clickable to show history, editable on long press
                HStack {
                    Button(action: {
                        let exerciseName = exercise.name.isEmpty ? "Unnamed Exercise" : exercise.name
                        onExerciseNameTap(exerciseName)
                    }) {
                        Text(exercise.name.isEmpty ? "Unnamed Exercise" : exercise.name)
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                
                GeometryReader { geometry in
                    HStack(spacing: 10) {
                        // Weight column with comma-separated values
                        TextField("Enter Weight", text: Binding(
                            get: { 
                                return exercise.weightString ?? ""
                            },
                                    set: { newValue in
                                        guard let index = index else { return }
                                        editedExercises[index].weightString = newValue
                                        delayedSave()
                                    }
                        ))
                        .font(.callout)
                        .textFieldStyle(DefaultTextFieldStyle())
                        .multilineTextAlignment(.leading)
                        .keyboardType(.numbersAndPunctuation)
                        .focused($isWeightFocused)
                        .frame(width: geometry.size.width * 0.6)
                        .onSubmit {
                            immediateSave()
                        }
                        
                        // Reps column with comma-separated values
                        TextField("Enter Reps", text: Binding(
                            get: { 
                                return exercise.repsString ?? ""
                            },
                                    set: { newValue in
                                        guard let index = index else { return }
                                        editedExercises[index].repsString = newValue
                                        delayedSave()
                                    }
                        ))
                        .font(.callout)
                        .textFieldStyle(DefaultTextFieldStyle())
                        .multilineTextAlignment(.center)
                        .keyboardType(.numbersAndPunctuation)
                        .focused($isRepsFocused)
                        .frame(width: geometry.size.width * 0.4)
                        .onSubmit {
                            immediateSave()
                        }
                    }
                }
                .frame(height: 50)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            
            if let index = index, index < editedExercises.count - 1 {
                Divider()
                    .padding(.leading, 16)
            }
        }
    }
    
}

struct ExerciseEditorView: View {
    let workoutDay: UserProfile.WorkoutDay?
    let onDismiss: () -> Void
    @EnvironmentObject var userProfileStore: UserProfileStore
    @State private var exerciseName = ""
    @State private var weightString = ""
    @State private var repsString = ""
    @State private var exercises: [ExerciseTemplate] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let workout = workoutDay {
                    Text("Add Exercises to \(workout.name)")
                        .font(.headline)
                        .padding()
                    
                    VStack(spacing: 16) {
                        TextField("Exercise Name", text: $exerciseName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        HStack {
                            TextField("Weight (e.g., 225, 225, 220)", text: $weightString)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numbersAndPunctuation)
                            
                            TextField("Reps (e.g., 7, 6, 9)", text: $repsString)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numbersAndPunctuation)
                        }
                        
                        Button("Add Exercise") {
                            addExercise()
                        }
                        .disabled(exerciseName.isEmpty)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                    
                    List {
                        ForEach(exercises) { exercise in
                            VStack(alignment: .leading) {
                                Text(exercise.name)
                                    .font(.headline)
                                if let weight = exercise.weightString, !weight.isEmpty {
                                    Text("Weight: \(weight)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                if let reps = exercise.repsString, !reps.isEmpty {
                                    Text("Reps: \(reps)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteExercise)
                    }
                } else {
                    Text("No workout selected")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExercises()
                        onDismiss()
                    }
                    .disabled(exercises.isEmpty)
                }
            }
            .onAppear {
                exercises = workoutDay?.exercises ?? []
            }
        }
    }
    
    private func addExercise() {
        let newExercise = ExerciseTemplate(
            name: exerciseName,
            weight: nil,
            reps: nil,
            weightString: weightString.isEmpty ? nil : weightString,
            repsString: repsString.isEmpty ? nil : repsString
        )
        exercises.append(newExercise)
        
        // Clear input fields
        exerciseName = ""
        weightString = ""
        repsString = ""
    }
    
    private func deleteExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }
    
    private func saveExercises() {
        // saveExercises called
        
        guard let workout = workoutDay,
              var profile = userProfileStore.profile,
              let workoutIndex = profile.workoutSplit.firstIndex(where: { $0.id == workout.id }) else {
            // Failed to save: missing workout, profile, or workoutIndex
            return
        }
        
        // Found workout at index
        profile.workoutSplit[workoutIndex].exercises = exercises
        userProfileStore.profile = profile
        // Saved exercises to workout split
    }
}

#Preview {
    HomeView()
        .environmentObject(WorkoutStore())
        .environmentObject(UserProfileStore())
} 