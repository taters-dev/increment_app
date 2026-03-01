import SwiftUI

struct LoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text(message)
                    .font(.headline)
                    .foregroundColor(AppStyle.brandBlue)
            }
            .padding(32)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .shadow(radius: 20)
        }
    }
}
