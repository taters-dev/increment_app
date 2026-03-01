import SwiftUI

struct ProgressDashboardView: View {
    @EnvironmentObject var workoutStore: WorkoutStore
    @EnvironmentObject var userProfileStore: UserProfileStore
    @State private var showingEditBodyWeight = false
    @State private var showingEditExerciseGoal: ExerciseGoal? = nil
    @State private var showingExerciseGoal = false
    @State private var showingWeightGoal = false
    @State private var showingWorkoutsGoal = false

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

    private var weeklyWorkoutCount: Int {
        let calendar = Calendar.current
        let now = Date()
        return workoutStore.workouts.filter { workout in
            calendar.isDate(workout.date, equalTo: now, toGranularity: .weekOfYear) &&
            workout.name != "Progress Photo" &&
            workout.name != "Weight Update"
        }.count
    }

    private var monthlyWorkoutCount: Int {
        let calendar = Calendar.current
        let now = Date()
        return workoutStore.workouts.filter { workout in
            calendar.isDate(workout.date, equalTo: now, toGranularity: .month) &&
            workout.name != "Progress Photo" &&
            workout.name != "Weight Update"
        }.count
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                HeaderView(title: "Progress", subtitle: nil, showTitle: false)
                
                ScrollView {
                    VStack(spacing: AppStyle.sectionSpacing) {
                        HStack(spacing: 12) {
                            GoalActionButton(
                                title: "Exercise Goal",
                                systemImage: "dumbbell.fill",
                                action: { showingExerciseGoal = true }
                            )

                            GoalActionButton(
                                title: "Weight Goal",
                                systemImage: "scalemass.fill",
                                action: { showingWeightGoal = true }
                            )

                            GoalActionButton(
                                title: "Workouts Goal",
                                systemImage: "calendar.badge.checkmark",
                                action: { showingWorkoutsGoal = true }
                            )
                        }
                        .padding(.horizontal, AppStyle.cardPadding)
                        
                        if let profile = userProfileStore.profile {
                            VStack(spacing: AppStyle.sectionSpacing) {
                                if let workoutsGoal = profile.workoutsGoal {
                                    WorkoutsGoalCard(
                                        weeklyCount: weeklyWorkoutCount,
                                        weeklyTarget: workoutsGoal.weeklyTarget,
                                        monthlyCount: monthlyWorkoutCount,
                                        monthlyTarget: workoutsGoal.monthlyTarget
                                    )
                                }
                                if let bodyWeightGoal = profile.bodyWeightGoal {
                                    GoalCard(
                                        title: "Body Weight Goal",
                                        current: bodyWeightGoal.currentWeight,
                                        target: bodyWeightGoal.targetWeight,
                                        percentage: bodyWeightGoal.progressPercentage,
                                        data: bodyWeightData,
                                        targetDate: bodyWeightGoal.targetDate
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
                                        percentage: calculateProgress(current: goal.currentWeight, target: goal.targetWeight),
                                        targetDate: goal.targetDate
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
        .sheet(isPresented: $showingExerciseGoal) {
            AddExerciseGoalView(isPresented: $showingExerciseGoal)
                .environmentObject(userProfileStore)
                .environmentObject(workoutStore)
        }
        .sheet(isPresented: $showingWeightGoal) {
            EditBodyWeightGoalView(
                isPresented: $showingWeightGoal,
                initialGoal: userProfileStore.profile?.bodyWeightGoal
            )
            .environmentObject(userProfileStore)
            .environmentObject(workoutStore)
        }
        .sheet(isPresented: $showingWorkoutsGoal) {
            WorkoutsGoalEditorView(isPresented: $showingWorkoutsGoal)
                .environmentObject(userProfileStore)
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

struct GoalActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(AppStyle.brandBlue)
            .frame(maxWidth: .infinity, minHeight: 72)
            .padding(.vertical, 10)
            .background(AppStyle.cardBackground)
            .cornerRadius(AppStyle.cardCornerRadius)
            .shadow(color: AppStyle.cardShadow, radius: 8, x: 0, y: 4)
        }
    }
}

struct WorkoutsGoalEditorView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var userProfileStore: UserProfileStore
    @State private var weeklyTarget = ""
    @State private var monthlyTarget = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Workouts Goal")
                .font(.headline)
                .padding(.top)

            VStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Weekly Goal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("Workouts per week", text: $weeklyTarget)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 24, weight: .medium))
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                VStack(alignment: .leading) {
                    Text("Monthly Goal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("Workouts per month", text: $monthlyTarget)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 24, weight: .medium))
                            .frame(maxWidth: .infinity)
                    }
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
                    save()
                    isPresented = false
                }
                .disabled(!isValid)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(width: UIScreen.main.bounds.width * 0.85)
        .padding(.bottom, 16)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: AppStyle.cardShadow, radius: 10, x: 0, y: 6)
        .onAppear {
            if let goal = userProfileStore.profile?.workoutsGoal {
                weeklyTarget = String(goal.weeklyTarget)
                monthlyTarget = String(goal.monthlyTarget)
            }
        }
    }

    private var isValid: Bool {
        Int(weeklyTarget) != nil && Int(monthlyTarget) != nil
    }

    private func save() {
        guard let weekly = Int(weeklyTarget),
              let monthly = Int(monthlyTarget),
              weekly > 0,
              monthly > 0 else { return }

        if var profile = userProfileStore.profile {
            profile.workoutsGoal = WorkoutsGoal(weeklyTarget: weekly, monthlyTarget: monthly)
            userProfileStore.profile = profile
            Task { @MainActor in
                await userProfileStore.saveProfile()
            }
        }
    }
}

struct WorkoutsGoalCard: View {
    let weeklyCount: Int
    let weeklyTarget: Int
    let monthlyCount: Int
    let monthlyTarget: Int

    var body: some View {
        HStack(spacing: 14) {
            WorkoutGoalGaugeCard(
                completed: weeklyCount,
                target: weeklyTarget,
                periodLabel: "Week"
            )

            WorkoutGoalGaugeCard(
                completed: monthlyCount,
                target: monthlyTarget,
                periodLabel: "Month"
            )
        }
    }
}

struct WorkoutGoalGaugeCard: View {
    let completed: Int
    let target: Int
    let periodLabel: String

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(completed) / Double(target), 1.0)
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                HalfCircleProgressShape()
                    .stroke(
                        AppStyle.brandBlue.opacity(0.14),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )

                HalfCircleProgressShape(progress: progress)
                    .stroke(
                        AppStyle.brandBlue,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )

                VStack(spacing: 2) {
                    Text("\(completed) / \(target)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppStyle.brandBlue)
                    Text("completed")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .offset(y: 8)
            }
            .frame(height: 86)

            Text(periodLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppStyle.brandBlue)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .background(AppStyle.cardBackground)
        .cornerRadius(AppStyle.cardCornerRadius)
        .shadow(color: AppStyle.cardShadow, radius: 10, x: 0, y: 6)
    }
}

struct HalfCircleProgressShape: Shape {
    var progress: Double = 1.0

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width / 2, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let clampedProgress = min(max(progress, 0), 1)
        let endAngle = Angle.degrees(180 + (180 * clampedProgress))

        var path = Path()
        path.addArc(
            center: center,
            radius: radius - 8,
            startAngle: .degrees(180),
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

struct ExerciseGoalCard: View {
    let title: String
    let current: Double
    let target: Double
    let percentage: Double
    let targetDate: Date?

    private var formattedTargetDate: String? {
        guard let targetDate else { return nil }
        return targetDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            Text("\(String(format: "%.1f", current))lbs / \(String(format: "%.1f", target))lbs")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let formattedTargetDate {
                Text("Target date: \(formattedTargetDate)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
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
    let targetDate: Date?

    private var formattedTargetDate: String? {
        guard let targetDate else { return nil }
        return targetDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            Text("\(String(format: "%.1f", current))lbs / \(String(format: "%.1f", target))lbs")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let formattedTargetDate {
                Text("Target date: \(formattedTargetDate)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
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
    ProgressDashboardView()
        .environmentObject(WorkoutStore())
        .environmentObject(UserProfileStore())
} 
