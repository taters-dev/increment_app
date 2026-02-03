import SwiftUI

struct AddExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (ExerciseTemplate) -> Void
    
    @State private var exerciseName = ""
    @State private var isTextFieldFocused = false
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise Info")) {
                    TextField("Exercise Name", text: $exerciseName)
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        hideKeyboard()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        hideKeyboard()
                        save()
                    }
                    .disabled(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                // View appeared
            }
            .onDisappear {
                // View disappeared
            }
        }
    }
    
    private func save() {
        let exercise = ExerciseTemplate(
            id: UUID(),
            name: exerciseName.trimmingCharacters(in: .whitespacesAndNewlines),
            weight: nil,
            reps: nil,
            weightString: nil,
            repsString: nil
        )
        onSave(exercise)
        dismiss()
    }
}

#Preview {
    AddExerciseView { exercise in
        // Exercise created
    }
}
