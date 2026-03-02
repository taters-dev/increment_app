import SwiftUI
import UIKit

enum SecureStorageBucket {
    case profileImages
    case progressPhotos
}

private enum SecureStorageImageCache {
    static let shared = NSCache<NSString, UIImage>()
}

struct SecureStorageImage<Content: View, Placeholder: View>: View {
    let reference: String?
    let bucket: SecureStorageBucket
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?
    @State private var didFail = false

    var body: some View {
        Group {
            if let uiImage {
                content(Image(uiImage: uiImage))
            } else if didFail {
                placeholder()
            } else {
                placeholder()
            }
        }
        .task(id: reference) {
            await loadURL()
        }
    }

    @MainActor
    private func loadURL() async {
        didFail = false
        uiImage = nil

        guard let reference, !reference.isEmpty else {
            return
        }

        let cacheKey = "\(bucket.cachePrefix):\(reference)" as NSString
        if let cachedImage = SecureStorageImageCache.shared.object(forKey: cacheKey) {
            uiImage = cachedImage
            return
        }

        do {
            let imageData: Data?
            switch bucket {
            case .profileImages:
                imageData = try await SupabaseStore.shared.downloadProfileImageData(from: reference)
            case .progressPhotos:
                imageData = try await SupabaseStore.shared.downloadProgressPhotoData(from: reference)
            }

            guard let imageData, let downloadedImage = UIImage(data: imageData) else {
                didFail = true
                return
            }

            SecureStorageImageCache.shared.setObject(downloadedImage, forKey: cacheKey)
            uiImage = downloadedImage
        } catch {
            didFail = true
        }
    }
}

private extension SecureStorageBucket {
    var cachePrefix: String {
        switch self {
        case .profileImages:
            return "profile"
        case .progressPhotos:
            return "progress"
        }
    }
}
