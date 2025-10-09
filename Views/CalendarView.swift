import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var workoutStore: WorkoutStore
    @State private var selectedDate = Date()
    @State private var showingWorkoutDetail = false
    @State private var selectedWorkout: Workout?
    @State private var showingFullScreenImage = false
    
    private var datesWithWorkouts: Set<Date> {
        let dates = Workout.datesWithWorkouts(workoutStore.workouts)
        return dates
    }
    
    private var workoutsForSelectedDate: [Workout] {
        Workout.workoutsForDate(selectedDate, workouts: workoutStore.workouts)
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                // Fixed header - doesn't scroll
                VStack(spacing: 8) {
                    Text("INCREMENT")
                        .font(.system(size: 16, weight: .bold, design: .default))
                        .italic()
                        .foregroundColor(Color(red: 11/255, green: 20/255, blue: 64/255))
                    
                    Text("Calendar")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 10)
                .padding(.top, 20)
                .background(Color.white)
                
                // Scrollable content - only this part scrolls
                ScrollView {
                    VStack(spacing: 16) {
                        // Calendar
                        CalendarViewComponent(
                            selectedDate: $selectedDate,
                            datesWithWorkouts: datesWithWorkouts
                        )
                        .padding(.horizontal, 16)
                        
                        // Workouts for selected date
                        VStack(alignment: .leading, spacing: 8) {
                            if workoutsForSelectedDate.isEmpty {
                                Text("No workouts recorded")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 40)
                            } else {
                                ForEach(workoutsForSelectedDate) { workout in
                                    Button(action: {
                                        selectedWorkout = workout
                                        if workout.name == "Progress Photo" {
                                            showingFullScreenImage = true
                                        } else if workout.name == "Weight Update" {
                                            // Weight updates don't show popup - do nothing
                                            return
                                        } else {
                                            showingWorkoutDetail = true
                                        }
                                    }) {
                                        WorkoutHistoryRow(workout: workout)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color.white)
                                            .cornerRadius(8)
                                            .foregroundColor(.primary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if let index = workoutsForSelectedDate.firstIndex(where: { $0.id == workout.id }) {
                                                deleteWorkouts(at: IndexSet(integer: index))
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 10)
                }
            }
            
            // Modal overlays (on top of everything)
            if showingFullScreenImage, 
                   let workout = selectedWorkout,
                   let photoData = workout.progressPhotoData,
                   let image = UIImage(data: photoData) {
                    // Progress photo modal
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showingFullScreenImage = false
                                selectedWorkout = nil
                            }
                        }
                    
                    GeometryReader { geometry in
                        VStack {
                            VStack {
                                // Header with title
                                HStack {
                                    Text("Progress Photo")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding()
                                
                                // Image
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                
                                Spacer()
                                
                                // Footer with close button
                                HStack {
                                    Button("Close") {
                                        withAnimation {
                                            showingFullScreenImage = false
                                            selectedWorkout = nil
                                        }
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color(red: 11/255, green: 20/255, blue: 64/255))
                                    .cornerRadius(8)
                                    
                                    Spacer()
                                }
                                .padding()
                            }
                            .frame(width: UIScreen.main.bounds.width * 0.85)
                            .frame(maxHeight: geometry.size.height * 0.8)
                            .background(Color.white)
                            .cornerRadius(15)
                            .background(Color.gray.opacity(0.2))
                        }
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                    }
                }
            
            if showingWorkoutDetail,
                   let workout = selectedWorkout {
                    // Workout detail overlay
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showingWorkoutDetail = false
                                selectedWorkout = nil
                            }
                        }
                    
                    GeometryReader { geometry in
                        VStack {
                            WorkoutDetailView(workout: workout) {
                                withAnimation {
                                    showingWorkoutDetail = false
                                    selectedWorkout = nil
                                }
                            }
                            .environmentObject(workoutStore)
                            .frame(width: UIScreen.main.bounds.width * 0.85)
                            .frame(maxHeight: geometry.size.height * 0.7)
                            .background(Color.white)
                            .cornerRadius(15)
                            .background(Color.gray.opacity(0.2))
                        }
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                    }
                }
            }
        .onAppear {
            // Ensure we have the latest workout data
            Task {
                try? await workoutStore.load()
            }
        }
    }
    
    private func deleteWorkouts(at offsets: IndexSet) {
        for index in offsets {
            let workout = workoutsForSelectedDate[index]
            workoutStore.deleteWorkout(workout)
        }
    }
}

struct CalendarViewComponent: View {
    @Binding var selectedDate: Date
    let datesWithWorkouts: Set<Date>
    
    var body: some View {
        VStack(spacing: 8) {
            // Month and Year header
            HStack {
                Text(monthYearString(from: selectedDate))
                    .font(.title2)
                    .bold()
                Spacer()
                HStack(spacing: 24) {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .imageScale(.large)
                            .padding(8)
                    }
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .imageScale(.large)
                            .padding(8)
                    }
                }
            }
            
            // Days of week
            HStack {
                ForEach(Calendar.current.veryShortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 4)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            hasWorkout: datesWithWorkouts.contains(Calendar.current.startOfDay(for: date))
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fill)
                    }
                }
            }
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func previousMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func nextMonth() {
        selectedDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
    }
    
    private func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: selectedDate)!
        let firstDay = interval.start
        
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let offsetDays = firstWeekday - calendar.firstWeekday
        
        let lastDay = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDay)!
        let daysInMonth = calendar.component(.day, from: lastDay)
        
        var days: [Date?] = Array(repeating: nil, count: offsetDays)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let hasWorkout: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color(red: 0.043, green: 0.063, blue: 0.282) : Color.clear)
            
            VStack {
                Text("\(Calendar.current.component(.day, from: date))")
                    .foregroundColor(isSelected ? .white : .primary)
                
                if hasWorkout {
                    Circle()
                        .fill(isSelected ? .white : Color(red: 0.043, green: 0.063, blue: 0.282))
                        .frame(width: 4, height: 4)
                }
            }
        }
        .aspectRatio(1, contentMode: .fill)
    }
}

struct WorkoutHistoryRow: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(workout.name)
                .font(.headline)
            
            HStack {
                if let bodyWeight = workout.bodyWeight {
                    Label("\(String(format: "%.1f", bodyWeight))lbs", systemImage: "scalemass")
                        .font(.caption)
                }
                
                if workout.progressPhotoData != nil {
                    Image(systemName: "photo")
                        .font(.caption)
                }
            }
            .foregroundColor(.secondary)
        }
    }
}

struct WorkoutHistoryDetailView: View {
    let workout: Workout
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Workout Info")) {
                    LabeledContent("Date", value: workout.formattedDate)
                    if let bodyWeight = workout.bodyWeight {
                        LabeledContent("Body Weight", value: "\(String(format: "%.1f", bodyWeight))lbs")
                    }
                    if let notes = workout.notes {
                        Text("Notes: \(notes)")
                    }
                }
                
                if let photoData = workout.progressPhotoData,
                   let image = UIImage(data: photoData) {
                    Section(header: Text("Progress Photo")) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    }
                }
                
                Section(header: Text("Exercises")) {
                    ForEach(workout.exercises) { exercise in
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .font(.headline)
                            ForEach(exercise.sets) { set in
                                HStack {
                                    Text("\(set.reps) reps × \(String(format: "%.1f", set.weight))lbs")
                                        .foregroundColor(.secondary)
                                    if set.isCompleted {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(workout.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(WorkoutStore())
}
