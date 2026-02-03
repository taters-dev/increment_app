import SwiftUI

struct ExerciseHistoryView: View {
    let exerciseName: String
    @EnvironmentObject var workoutStore: WorkoutStore
    @Environment(\.dismiss) private var dismiss
    
    private var exerciseHistory: [(Date, [ExerciseSet])] {
        workoutStore.workouts
            .flatMap { workout in
                workout.exercises
                    .filter { $0.name == exerciseName }
                    .map { exercise in
                        (workout.date, exercise.sets)
                    }
            }
            .sorted { $0.0 > $1.0 } // Most recent first
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Header with INCREMENT title
                    VStack(spacing: 8) {
                        Text("INCREMENT")
                            .font(.system(size: 16, weight: .bold, design: .default))
                            .italic()
                            .foregroundColor(Color(red: 11/255, green: 20/255, blue: 64/255))
                        
                        Text(exerciseName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Exercise History")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    if exerciseHistory.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.line.downtrend.xyaxis")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No History Found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Start tracking this exercise to see your progress over time.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                    } else {
                        // History List
                        List {
                            ForEach(Array(exerciseHistory.enumerated()), id: \.offset) { index, entry in
                                let (date, sets) = entry
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    // Date header
                                    Text(formatDate(date))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    // Weight and Reps columns
                                    HStack(alignment: .top, spacing: 20) {
                                        // Weight column
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Weight")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.secondary)
                                            
                                            ForEach(sets, id: \.id) { set in
                                                Text("\(String(format: "%.1f", set.weight))")
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        // Reps column
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Reps")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.secondary)
                                            
                                            ForEach(sets, id: \.id) { set in
                                                Text("\(set.reps)")
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .cornerRadius(8)
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                    }
                    
                    // Footer with Done button
                    HStack {
                        Spacer()
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(red: 11/255, green: 20/255, blue: 64/255))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .frame(width: UIScreen.main.bounds.width * 0.85)
                .frame(maxHeight: geometry.size.height * 0.7)
                .background(Color.white)
                .cornerRadius(15)
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    ExerciseHistoryView(exerciseName: "Bench Press")
        .environmentObject(WorkoutStore())
}
