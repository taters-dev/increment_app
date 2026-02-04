import SwiftUI

struct ProgressView: View {
    @EnvironmentObject var workoutStore: WorkoutStore
    @EnvironmentObject var userProfileStore: UserProfileStore
    @State private var showingEditBodyWeight = false
    @State private var showingEditExerciseGoal: ExerciseGoal? = nil
    @State private var showingGoalUpdate = false

    private func exerciseData(for exerciseName: String) -> [(Date, Double)] {
        return workoutStore.workouts
            .flatMap { workout in
                workout.exercises
                    .filter { $0.name == exerciseName }
                    .compactMap { exercise -> (Date, Double)? in
                        guard let maxWeight = exercise.sets.map({ $0.weight }).max() else { return nil }
                        return (workout.date, maxWeight)
                    }
            }
            .sorted { $0.0 < $1.0 }
    }
    
    private var bodyWeightData: [(Date, Double)] {
        workoutStore.workouts
            .compactMap { workout -> (Date, Double)? in
                guard let weight = workout.bodyWeight else { return nil }
                return (workout.date, weight)
            }
            .sorted { $0.0 < $1.0 }
    }
    
    var body: some View {
        ZStack {
            AppStyle.canvas.ignoresSafeArea()
            VStack(spacing: 0) {
                HeaderView(title: "Progress", subtitle: nil, showTitle: false)
                
                ScrollView {
                    VStack(spacing: AppStyle.sectionSpacing) {
                        Button(action: { showingGoalUpdate = true }) {
                            HStack {
                                Image(systemName: "target")
                                    .font(.title2)
                                Text("Update Goals")
                                    .font(.headline)
                            }
                            .foregroundColor(AppStyle.brandBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .padding(.horizontal, AppStyle.cardPadding)
                        .background(AppStyle.cardBackground)
                        .cornerRadius(AppStyle.cardCornerRadius)
                        .shadow(color: AppStyle.cardShadow, radius: 10, x: 0, y: 6)
                        .padding(.horizontal, AppStyle.cardPadding)
                        
                        if let profile = userProfileStore.profile {
                            VStack(spacing: AppStyle.sectionSpacing) {
                                if let bodyWeightGoal = profile.bodyWeightGoal {
                                    GoalCard(
                                        title: "Body Weight Goal",
                                        current: bodyWeightGoal.currentWeight,
                                        target: bodyWeightGoal.targetWeight,
                                        percentage: bodyWeightGoal.progressPercentage,
                                        data: bodyWeightData
                                    )
                                    .onTapGesture {
                                        showingEditBodyWeight = true
                                    }
                                }
                                
                                ForEach(profile.goals) { goal in
                                    ExerciseGoalCard(
                                        title: goal.exerciseName,
                                        current: goal.currentWeight,
                                        target: goal.targetWeight,
                                        percentage: calculateProgress(current: goal.currentWeight, target: goal.targetWeight)
                                    )
                                    .onTapGesture {
                                        showingEditExerciseGoal = goal
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button("Delete", role: .destructive) {
                                            deleteExerciseGoal(goal)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, AppStyle.cardPadding)
                        } else {
                            Text("No profile found")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, AppStyle.cardPadding)
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
        .sheet(isPresented: $showingEditBodyWeight) {
            if let bodyWeightGoal = userProfileStore.profile?.bodyWeightGoal {
                EditBodyWeightGoalView(
                    isPresented: $showingEditBodyWeight,
                    initialGoal: bodyWeightGoal
                )
            }
        }
        .sheet(item: $showingEditExerciseGoal) { goal in
            EditExerciseGoalView(
                isPresented: Binding(
                    get: { showingEditExerciseGoal != nil },
                    set: { if !$0 { showingEditExerciseGoal = nil } }
                ),
                initialGoal: goal
            )
        }
        .sheet(isPresented: $showingGoalUpdate) {
            GoalUpdateView(
                onDismiss: { showingGoalUpdate = false }
            )
            .environmentObject(userProfileStore)
        }
    }
    
    private func deleteBodyWeightGoal() {
        guard var profile = userProfileStore.profile else {
            return 
        }
        profile.bodyWeightGoal = nil
        userProfileStore.profile = profile
        Task {
            await userProfileStore.saveProfile()
        }
    }
    
    private func deleteExerciseGoals(at offsets: IndexSet) {
        guard var profile = userProfileStore.profile else { return }
        profile.goals.remove(atOffsets: offsets)
        userProfileStore.profile = profile
        Task {
            await userProfileStore.saveProfile()
        }
    }
    
    private func deleteExerciseGoal(_ goal: ExerciseGoal) {
        guard var profile = userProfileStore.profile else {
            return 
        }
        profile.goals.removeAll { $0.id == goal.id }
        userProfileStore.profile = profile
        Task {
            await userProfileStore.saveProfile()
        }
    }
    
    private func calculateProgress(current: Double, target: Double) -> Double {
        guard target != 0 else { return 0 }
        
        // For exercise goals: progress = current weight / target weight
        // Example: 225 lbs current / 315 lbs target = 71.4% progress
        let progress = (current / target) * 100
        return min(max(progress, 0), 100)
    }
}

struct ExerciseGoalCard: View {
    let title: String
    let current: Double
    let target: Double
    let percentage: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            Text("\(String(format: "%.1f", current))lbs / \(String(format: "%.1f", target))lbs")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 10)
                        .opacity(0.3)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(width: min(CGFloat(percentage) * geometry.size.width / 100, geometry.size.width), height: 10)
                        .foregroundColor(Color(red: 0.043, green: 0.063, blue: 0.282))
                }
                .cornerRadius(5)
            }
            .frame(height: 10)
        }
        .padding(AppStyle.cardPadding)
        .background(AppStyle.cardBackground)
        .cornerRadius(AppStyle.cardCornerRadius)
        .shadow(color: AppStyle.cardShadow, radius: 10, x: 0, y: 6)
    }
}

struct GoalCard: View {
    let title: String
    let current: Double
    let target: Double
    let percentage: Double
    let data: [(Date, Double)] // Keep for compatibility but don't use
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            Text("\(String(format: "%.1f", current))lbs / \(String(format: "%.1f", target))lbs")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 10)
                        .opacity(0.3)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(width: min(CGFloat(percentage) * geometry.size.width / 100, geometry.size.width), height: 10)
                        .foregroundColor(Color(red: 0.043, green: 0.063, blue: 0.282))
                }
                .cornerRadius(5)
            }
            .frame(height: 10)
        }
        .padding(AppStyle.cardPadding)
        .background(AppStyle.cardBackground)
        .cornerRadius(AppStyle.cardCornerRadius)
        .shadow(color: AppStyle.cardShadow, radius: 10, x: 0, y: 6)
    }
}

#Preview {
    ProgressView()
        .environmentObject(WorkoutStore())
        .environmentObject(UserProfileStore())
} 
