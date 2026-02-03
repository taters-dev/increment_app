import SwiftUI

struct WeightUpdateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutStore: WorkoutStore
    @EnvironmentObject var userProfileStore: UserProfileStore
    @Binding var bodyWeight: String
    let onDismiss: () -> Void
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Update Weight")
                .font(.headline)
                .padding(.top)
            
            VStack(spacing: 12) {
                HStack {
                    TextField("Enter Weight", text: $bodyWeight)
                        .focused($isInputFocused)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 28, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .onChange(of: bodyWeight) { oldValue, newValue in
                            // Only allow one decimal point
                            if newValue.filter({ $0 == "." }).count > 1 {
                                bodyWeight = oldValue
                                return
                            }
                            
                            // Filter out any non-numeric characters except decimal point
                            let filtered = newValue.filter { "0123456789.".contains($0) }
                            if filtered != newValue {
                                bodyWeight = filtered
                            }
                            
                            // Ensure proper decimal format
                            if let dotIndex = filtered.firstIndex(of: ".") {
                                let decimals = filtered[filtered.index(after: dotIndex)...]
                                if decimals.count > 1 {
                                    bodyWeight = String(filtered[...filtered.index(dotIndex, offsetBy: 2)])
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
            .padding(.horizontal)
            
            HStack {
                Button("Cancel") {
                    isInputFocused = false
                    onDismiss()
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Save") {
                    isInputFocused = false
                    saveWeight()
                    onDismiss()
                }
                .disabled(bodyWeight.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: UIScreen.main.bounds.width * 0.85)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputFocused = false
                }
            }
        }
    }
    
    private func saveWeight() {
        guard let weight = Double(bodyWeight) else { return }
        
        // Update body weight goal if it exists
        if var profile = userProfileStore.profile {
            if var bodyWeightGoal = profile.bodyWeightGoal {
                bodyWeightGoal.currentWeight = weight
                profile.bodyWeightGoal = bodyWeightGoal
                userProfileStore.profile = profile
                Task {
                    await userProfileStore.saveProfile()
                }
            }
        }
        
        // Find or create a weight tracking entry for today
        let today = Calendar.current.startOfDay(for: Date())
        
        // Check if a "Weight Update" workout already exists for today
        if let existingIndex = workoutStore.workouts.firstIndex(where: { workout in
            Calendar.current.isDate(workout.date, inSameDayAs: today) && workout.name == "Weight Update"
        }) {
            // Update existing workout
            workoutStore.workouts[existingIndex].bodyWeight = weight        } else {
            // Create new workout
            let workout = Workout(
                date: Date(),
                name: "Weight Update",
                exercises: [],
                bodyWeight: weight
            )
            workoutStore.workouts.append(workout)        }
        
        Task {
            await workoutStore.saveWorkouts()
        }
    }
}

#Preview {
    WeightUpdateView(bodyWeight: .constant(""), onDismiss: {})
        .environmentObject(WorkoutStore())
        .environmentObject(UserProfileStore())
} 