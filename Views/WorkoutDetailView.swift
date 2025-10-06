import SwiftUI
import PhotosUI

struct WorkoutDetailView: View {
    @State var workout: Workout
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutStore: WorkoutStore
    @State private var showingAddExercise = false
    @State private var editMode: EditMode = .inactive
    @State private var notes: String
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var bodyWeight: String
    @State private var showingCamera = false
    @State private var showingFullScreenImage = false
    @State private var showingExerciseHistory = false
    @State private var selectedExerciseForHistory: String = ""
    var onDismiss: () -> Void
    
    init(workout: Workout, onDismiss: @escaping () -> Void = {}) {
        _workout = State(initialValue: workout)
        _notes = State(initialValue: workout.notes ?? "")
        _bodyWeight = State(initialValue: workout.bodyWeight.map { String(format: "%.1f", $0) } ?? "")
        self.onDismiss = onDismiss
    }
    
    private func cancelEditing() {
        if let originalWorkout = workoutStore.workouts.first(where: { $0.id == workout.id }) {
            workout = originalWorkout
            notes = originalWorkout.notes ?? ""
            bodyWeight = originalWorkout.bodyWeight.map { String(format: "%.1f", $0) } ?? ""
        }
        editMode = .inactive
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text(workout.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                // Edit functionality removed - workouts cannot be edited from calendar view
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Content
            List {
                VStack(spacing: 16) {
                    if let bodyWeight = workout.bodyWeight {
                        Text("\(String(format: "%.1f", bodyWeight)) lbs")
                            .font(.headline)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                
                if workout.name == "Progress Photo" {
                    if let photoData = workout.progressPhotoData,
                       let image = UIImage(data: photoData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .onTapGesture {
                                showingFullScreenImage = true
                            }
                    }
                    
                    HStack {
                        Button(action: { showingCamera = true }) {
                            Label("Take New Photo", systemImage: "camera")
                        }
                        
                        Divider()
                        
                        PhotosPicker(selection: $selectedItem,
                                   matching: .images) {
                            Label("Choose New Photo", systemImage: "photo")
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                
                if !workout.exercises.isEmpty {
                    ForEach(workout.exercises) { exercise in
                        VStack(alignment: .leading, spacing: 8) {
                            Button(action: {
                                selectedExerciseForHistory = exercise.name
                                showingExerciseHistory = true
                            }) {
                                Text(exercise.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 8)
                            
                            ForEach(exercise.sets.indices, id: \.self) { index in
                                let set = exercise.sets[index]
                                HStack {
                                    Text("Set \(index + 1)")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if editMode == .active {
                                        TextField("Reps", value: $workout.exercises[getExerciseIndex(exercise)].sets[index].reps, format: .number)
                                            .keyboardType(.numberPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 60)
                                        Text("×")
                                        TextField("Weight", value: $workout.exercises[getExerciseIndex(exercise)].sets[index].weight, format: .number)
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 60)
                                        Text("lbs")
                                        
                                        Button(action: { deleteSet(from: exercise, at: index) }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    } else {
                                        Text("\(set.reps) reps × \(String(format: "%.1f", set.weight))lbs")
                                            .foregroundColor(.primary)
                                    }
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            if editMode == .active {
                                Button(action: { addSet(to: exercise) }) {
                                    Label("Add Set", systemImage: "plus.circle.fill")
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            
            // Footer
            HStack(spacing: 12) {
                Button("Close") {
                    if editMode == .active {
                        cancelEditing()
                    }
                    onDismiss()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(red: 11/255, green: 20/255, blue: 64/255))
                .cornerRadius(8)
                
                Spacer()
                
                if editMode == .active {
                    Button("Cancel") {
                        cancelEditing()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.7))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .onChange(of: selectedItem) { item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let compressedData = image.jpegData(compressionQuality: 0.8) {
                    workout.progressPhotoData = compressedData
                    saveWorkout()
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(selectedImage: Binding(
                get: {
                    if let data = workout.progressPhotoData {
                        return UIImage(data: data)
                    }
                    return nil
                },
                set: { newImage in
                    if let image = newImage,
                       let compressedData = image.jpegData(compressionQuality: 0.8) {
                        workout.progressPhotoData = compressedData
                        saveWorkout()
                    }
                }
            ), sourceType: .camera)
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            if let photoData = workout.progressPhotoData,
               let image = UIImage(data: photoData) {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { showingFullScreenImage = false }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                        
                        Spacer()
                        
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onTapGesture {
                                showingFullScreenImage = false
                            }
                        
                        Spacer()
                    }
                }
            }
        }
        .onDisappear {
            if editMode == .active {
                cancelEditing()
            }
        }
        .sheet(isPresented: $showingExerciseHistory) {
            ExerciseHistoryView(exerciseName: selectedExerciseForHistory)
                .environmentObject(workoutStore)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? ""
    }
    
    private func getExerciseIndex(_ exercise: Exercise) -> Int {
        workout.exercises.firstIndex(where: { $0.id == exercise.id }) ?? 0
    }
    
    private func addSet(to exercise: Exercise) {
        if let index = workout.exercises.firstIndex(where: { $0.id == exercise.id }) {
            let newSet = ExerciseSet(reps: 0, weight: 0)
            workout.exercises[index].sets.append(newSet)        }
    }
    
    private func deleteSet(from exercise: Exercise, at setIndex: Int) {
        if let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exercise.id }) {
            workout.exercises[exerciseIndex].sets.remove(at: setIndex)        }
    }
    
    private func saveWorkout() {
        if let index = workoutStore.workouts.firstIndex(where: { $0.id == workout.id }) {
            var updatedWorkout = workout
            updatedWorkout.notes = notes.isEmpty ? nil : notes
            
            if workout.name == "Weight Update",
               let weight = Double(bodyWeight) {
                updatedWorkout.bodyWeight = weight
            }
            
            workoutStore.workouts[index] = updatedWorkout
            
            // Also update the active workout if this is the current active workout
            if let activeWorkout = workoutStore.activeWorkout, activeWorkout.id == workout.id {
                workoutStore.updateActiveWorkout(updatedWorkout)
            } else {
                // If not active workout, just save normally
                Task {
                    await workoutStore.saveWorkouts()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        WorkoutDetailView(workout: Workout(
            date: Date(),
            name: "Sample Workout",
            exercises: [
                Exercise(
                    templateId: UUID(),
                    name: "Bench Press",
                    sets: [
                        ExerciseSet(reps: 10, weight: 60),
                        ExerciseSet(reps: 8, weight: 65)
                    ]
                )
            ]
        ))
        .environmentObject(WorkoutStore())
    }
} 