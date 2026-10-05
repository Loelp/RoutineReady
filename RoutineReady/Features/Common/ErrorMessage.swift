import Foundation

// Turns an error into the two bits of text we show: what went wrong, and what to do about it
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
