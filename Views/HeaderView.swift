import SwiftUI

struct HeaderView: View {
    let title: String
    let subtitle: String?
    var showTitle: Bool = true
    
    var body: some View {
        VStack(spacing: 8) {
            Text("INCREMENT")
                .font(.system(size: 16, weight: .bold, design: .default))
                .italic()
                .foregroundColor(AppStyle.brandBlue)
            
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(.secondary)
            } else if showTitle {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, AppStyle.headerTopPadding)
        .padding(.bottom, AppStyle.headerBottomPadding)
        .background(AppStyle.surface)
    }
}

#Preview {
    HeaderView(title: "Home", subtitle: nil)
}
