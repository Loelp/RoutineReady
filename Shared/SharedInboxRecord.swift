import Foundation

/// One photo shared from the Photos app, waiting in the App Group `Inbox/` for the app to file it
/// as a maintenance item. Written by the share extension, read and deleted by the app.
nonisolated struct SharedInboxRecord: Codable, Identifiable, Equatable {
    let id: UUID
    var inspectionID: UUID
    let room: String
    let note: String
    /// File name inside the App Group `Photos/` folder.
    let photoFilename: String
    let sharedAt: Date
}

/// An inspection the share extension can file photos against, listed in `share-inspections.json`.
nonisolated struct ShareableInspection: Codable, Identifiable, Equatable {
    let id: UUID
    let address: String
    let scheduledAt: Date
}
