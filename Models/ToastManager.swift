import Foundation
import SwiftUI

@MainActor
class ToastManager: ObservableObject {
    @Published var currentError: AppError?
    @Published var successMessage: String?
    @Published var isLoading = false
    @Published var loadingMessage = "Loading..."

    func showError(_ error: AppError) {
        currentError = error
        // Auto-dismiss after 5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if currentError?.id == error.id {
                currentError = nil
            }
        }
    }

    func showSuccess(_ message: String) {
        successMessage = message
        // Auto-dismiss after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if successMessage == message {
                successMessage = nil
            }
        }
    }

    func startLoading(_ message: String = "Loading...") {
        loadingMessage = message
        isLoading = true
    }

    func stopLoading() {
        isLoading = false
    }

    func dismissError() {
        currentError = nil
    }

    func dismissSuccess() {
        successMessage = nil
    }
}
