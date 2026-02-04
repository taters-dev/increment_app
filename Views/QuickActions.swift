import SwiftUI

struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title)
                    .foregroundColor(AppStyle.brandBlue)
                Text(title)
                    .font(.caption)
                    .bold()
                    .foregroundColor(AppStyle.brandBlue)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .contentShape(Rectangle())
        .buttonStyle(.plain)
    }
}

struct QuickActionsGrid: View {
    let onProgressPhotoTap: () -> Void
    let onWeightUpdateTap: () -> Void
    let onGoalUpdateTap: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            QuickActionButton(
                title: "Progress Photo",
                systemImage: "camera.fill",
                action: onProgressPhotoTap
            )
            QuickActionButton(
                title: "Update Weight",
                systemImage: "scalemass.fill",
                action: onWeightUpdateTap
            )
            QuickActionButton(
                title: "Update Goals",
                systemImage: "target",
                action: onGoalUpdateTap
            )
        }
        .padding(AppStyle.cardPadding)
        .background(AppStyle.cardBackground)
        .cornerRadius(AppStyle.cardCornerRadius)
        .shadow(color: AppStyle.cardShadow, radius: 10, x: 0, y: 6)
    }
}

#Preview {
    QuickActionsGrid(
        onProgressPhotoTap: {},
        onWeightUpdateTap: {},
        onGoalUpdateTap: {}
    )
}
