import SwiftUI

struct ProgressBar: View {
    let title: String
    let current: Double
    let target: Double
    let percentage: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack {
                Text("\(String(format: "%.1f", current)) lbs")
                    .font(.system(size: 16, weight: .medium))
                Spacer()
                Text("\(String(format: "%.1f", target)) lbs")
                    .font(.system(size: 16, weight: .medium))
            }
            .font(.subheadline)
            .foregroundColor(.gray)
            
            ProgressView()
                .progressViewStyle(.linear)
                .tint(Color(red: 0.043, green: 0.063, blue: 0.282))
            
            Text(String(format: "%.1f%%", percentage))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    ProgressBar(title: "Bench Press", current: 80.0, target: 100.0, percentage: 80.0)
} 