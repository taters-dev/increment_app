import SwiftUI
import PhotosUI

struct ProgressPhotoUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutStore: WorkoutStore
    @Binding var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Progress Photo")
                .font(.headline)
                .padding(.top)
            
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
            }
            
            VStack(spacing: 12) {
                Button(action: { showingCamera = true }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Take Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                PhotosPicker(selection: $selectedItem,
                           matching: .images) {
                    HStack {
                        Image(systemName: "photo")
                        Text("Choose Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            HStack {
                Button("Cancel") {
                    onDismiss()
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Save") {
                    saveProgressPhoto()
                    onDismiss()
                }
                .disabled(selectedImage == nil)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: UIScreen.main.bounds.width * 0.85)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .onChange(of: selectedItem) { item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
    }
    
    private func saveProgressPhoto() {
        guard let imageData = selectedImage?.jpegData(compressionQuality: 0.8) else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        
        // Check if a "Progress Photo" workout already exists for today
        if let existingIndex = workoutStore.workouts.firstIndex(where: { workout in
            Calendar.current.isDate(workout.date, inSameDayAs: today) && workout.name == "Progress Photo"
        }) {
            // Update existing workout
            workoutStore.workouts[existingIndex].progressPhotoData = imageData        } else {
            // Create new workout
            let workout = Workout(
                date: Date(),
                name: "Progress Photo",
                exercises: [],
                progressPhotoData: imageData
            )
            workoutStore.workouts.append(workout)        }
        
        Task {
            await workoutStore.saveWorkouts()
        }
    }
}

#Preview {
    ProgressPhotoUploadView(selectedImage: .constant(nil), onDismiss: {})
        .environmentObject(WorkoutStore())
} 
