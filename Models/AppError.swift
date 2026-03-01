import Foundation

enum AppError: Error, Identifiable {
    case network(String)
    case authentication(String)
    case storage(String)
    case validation(String)
    case unknown(String)

    var id: String {
        switch self {
        case .network(let msg): return "network_\(msg)"
        case .authentication(let msg): return "auth_\(msg)"
        case .storage(let msg): return "storage_\(msg)"
        case .validation(let msg): return "validation_\(msg)"
        case .unknown(let msg): return "unknown_\(msg)"
        }
    }

    var userMessage: String {
        switch self {
        case .network(let msg):
            return "Connection error: \(msg). Check your internet connection."
        case .authentication(let msg):
            return "Authentication failed: \(msg)"
        case .storage(let msg):
            return "Failed to save data: \(msg)"
        case .validation(let msg):
            return "Invalid input: \(msg)"
        case .unknown(let msg):
            return "An error occurred: \(msg)"
        }
    }

    var icon: String {
        switch self {
        case .network:
            return "wifi.slash"
        case .authentication:
            return "lock.slash"
        case .storage:
            return "externaldrive.badge.xmark"
        case .validation:
            return "exclamationmark.triangle"
        case .unknown:
            return "exclamationmark.circle"
        }
    }

    var color: String {
        switch self {
        case .validation:
            return "orange"
        default:
            return "red"
        }
    }
}
