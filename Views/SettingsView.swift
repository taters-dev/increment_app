import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject var userProfileStore: UserProfileStore
    @EnvironmentObject var workoutStore: WorkoutStore
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingWorkoutSplitEditor = false
    @State private var showingProfileEditor = false
    
    var body: some View {
        VStack(spacing: 0) {
            // App title at the top
            Text("INCREMENT")
                .font(.system(size: 16, weight: .bold, design: .default))
                .italic()
                .foregroundColor(Color(red: 11/255, green: 20/255, blue: 64/255))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 10)
                .padding(.top, 20)
            
            NavigationView {
                List {
                    if let profile = userProfileStore.profile {
                        Section {
                            HStack {
                                if let imageData = profile.profileImageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(profile.name)
                                        .font(.headline)
                                    Text(profile.email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    Section {
                        Button(action: { showingProfileEditor = true }) {
                            Label("Edit Profile", systemImage: "person")
                        }
                        .foregroundColor(.primary)
                        
                        PhotosPicker(selection: $selectedItem,
                                     matching: .images) {
                            Label("Change Profile Picture", systemImage: "photo")
                        }
                        .foregroundColor(.primary)
                        
                        Button(action: { showingWorkoutSplitEditor = true }) {
                            Label("Workout Split", systemImage: "calendar")
                        }
                        .foregroundColor(.primary)
                    }
                    
                    Section(header: Text("Account")) {
                        Button(action: {
                            Task {
                                await authManager.signOut()
                            }
                        }) {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        .foregroundColor(.red)
                    }
                    
                    .background(Color.white)
                    .navigationTitle("Settings")
                    .onChange(of: selectedItem) { item in
                        Task {
                            if let data = try? await item?.loadTransferable(type: Data.self) {
                                if var profile = userProfileStore.profile {
                                    profile.profileImageData = data
                                    userProfileStore.profile = profile
                                    await userProfileStore.saveProfile()
                                }
                            }
                        }
                    }
                    .sheet(isPresented: $showingProfileEditor) {
                        ProfileEditorView()
                            .environmentObject(userProfileStore)
                    }
                    .sheet(isPresented: $showingWorkoutSplitEditor) {
                        WorkoutSplitEditorView()
                            .environmentObject(userProfileStore)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
    }
}


struct ProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfileStore: UserProfileStore
    @State private var name = ""
    @State private var email = ""
    @State private var bio = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                        dismiss()
                    }
                    .disabled(name.isEmpty || email.isEmpty)
                }
            }
            .onAppear {
                if let profile = userProfileStore.profile {
                    name = profile.name
                    email = profile.email
                    bio = profile.bio
                }
            }
        }
    }
    
    private func saveProfile() {
        if var profile = userProfileStore.profile {
            profile.name = name
            profile.email = email
            profile.bio = bio
            userProfileStore.profile = profile
            Task {
                await userProfileStore.saveProfile()
            }
        }
    }
}

struct WorkoutSplitEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfileStore: UserProfileStore
    @State private var workoutDays: [UserProfile.WorkoutDay] = []
    @State private var showingAddWorkoutDay = false
    
    var body: some View {
        NavigationView {
            List {
                        ForEach(workoutDays) { workoutDay in
                            NavigationLink(destination: WorkoutDayDetailView(workoutDay: workoutDay) { updatedDay in
                                // Only update when explicitly saving, not on every state change
                                if let index = workoutDays.firstIndex(where: { $0.id == updatedDay.id }) {
                                    workoutDays[index] = updatedDay
                                    // Save changes immediately when a workout day is updated
                                    saveWorkoutSplit()
                                }
                            }) {
                                VStack(alignment: .leading) {
                                    Text(workoutDay.name)
                                        .font(.headline)
                                    Text("\(workoutDay.exercises.count) exercises")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteWorkoutDay)
                    }
                    .navigationTitle("Workout Split")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") {
                                saveWorkoutSplit()
                                dismiss()
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { showingAddWorkoutDay = true }) {
                                Image(systemName: "plus")
                            }
                        }
                    }
                    .onAppear {
                        workoutDays = userProfileStore.profile?.workoutSplit ?? []
                    }
                    .sheet(isPresented: $showingAddWorkoutDay) {
                        AddWorkoutDayView { workoutDay in
                            workoutDays.append(workoutDay)
                            // Save changes immediately when a new workout day is added
                            saveWorkoutSplit()
                        }
                    }
                }
            }
            
            private func deleteWorkoutDay(at offsets: IndexSet) {
                workoutDays.remove(atOffsets: offsets)
                // Save changes immediately when a workout day is deleted
                saveWorkoutSplit()
            }
            
            private func saveWorkoutSplit() {
                if var profile = userProfileStore.profile {
                    profile.workoutSplit = workoutDays
                    userProfileStore.profile = profile
                    Task {
                        await userProfileStore.saveProfile()
                    }
                }
            }
        }
        
        struct AddWorkoutDayView: View {
            @Environment(\.dismiss) private var dismiss
            let onSave: (UserProfile.WorkoutDay) -> Void
            
            @State private var name = ""
            @State private var exercises: [ExerciseTemplate] = []
            @State private var showingAddExercise = false
            
            var body: some View {
                NavigationView {
                    List {
                        Section(header: Text("Workout Day Info")) {
                            TextField("Day Name (e.g., Push Day)", text: $name)
                        }
                        
                        Section(header: Text("Exercises")) {
                            ForEach(exercises) { exercise in
                                Text(exercise.name)
                            }
                            .onDelete(perform: deleteExercise)
                            
                            Button(action: { showingAddExercise = true }) {
                                Label("Add Exercise", systemImage: "plus.circle.fill")
                            }
                        }
                    }
                    .navigationTitle("Add Workout Day")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Save") {
                                save()
                            }
                            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .sheet(isPresented: $showingAddExercise) {
                        AddExerciseView { exercise in
                            exercises.append(exercise)
                        }
                    }
                }
            }
            
            private func deleteExercise(at offsets: IndexSet) {
                exercises.remove(atOffsets: offsets)
            }
            
            private func save() {
                let workoutDay = UserProfile.WorkoutDay(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    exercises: exercises
                )
                onSave(workoutDay)
                dismiss()
            }
        }
        
        struct WorkoutDayDetailView: View {
            @Environment(\.dismiss) private var dismiss
            let workoutDay: UserProfile.WorkoutDay
            let onUpdate: (UserProfile.WorkoutDay) -> Void
            
            @State private var name: String
            @State private var exercises: [ExerciseTemplate]
            @State private var showingAddExercise = false
            
            init(workoutDay: UserProfile.WorkoutDay, onUpdate: @escaping (UserProfile.WorkoutDay) -> Void) {
                self.workoutDay = workoutDay
                self.onUpdate = onUpdate
                self._name = State(initialValue: workoutDay.name)
                self._exercises = State(initialValue: workoutDay.exercises)
            }
            
            var body: some View {
                List {
                    Section(header: Text("Workout Day Info")) {
                        TextField("Day Name", text: $name)
                    }
                    
                    Section(header: Text("Exercises")) {
                        ForEach(exercises) { exercise in
                            Text(exercise.name)
                        }
                        .onDelete(perform: deleteExercise)
                        
                        Button(action: { 
                            showingAddExercise = true 
                        }) {
                            Label("Add Exercise", systemImage: "plus.circle.fill")
                        }
                    }
                }
                .navigationTitle(name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            save()
                            dismiss()
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .fullScreenCover(isPresented: $showingAddExercise) {
                    AddExerciseView { exercise in
                        exercises.append(exercise)
                        showingAddExercise = false
                    }
                }
                .onChange(of: showingAddExercise) { newValue in
                    // showingAddExercise changed
                }
            }
            
            private func deleteExercise(at offsets: IndexSet) {
                exercises.remove(atOffsets: offsets)
            }
            
            private func save() {
                let updatedWorkoutDay = UserProfile.WorkoutDay(
                    id: workoutDay.id,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    exercises: exercises
                )
                onUpdate(updatedWorkoutDay)
            }
        }
        
        #Preview {
            SettingsView()
                .environmentObject(UserProfileStore())
                .environmentObject(WorkoutStore())
        }
