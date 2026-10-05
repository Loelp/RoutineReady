import Foundation

/// A use case error ready to show on screen: what went wrong, and what to do next.
struct ErrorMessage: Equatable {
    let title: String
    let suggestion: String?

    init(_ error: Error) {
        if let localizedError = error as? LocalizedError {
            title = localizedError.errorDescription ?? error.localizedDescription
            suggestion = localizedError.recoverySuggestion
        } else {
            title = error.localizedDescription
            suggestion = nil
        }
    }
}
