import SwiftUI

/// Shows a use case error inline, with its recovery suggestion underneath.
struct ErrorMessageView: View {
    let message: ErrorMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(message.title, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            if let suggestion = message.suggestion {
                Text(suggestion)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
