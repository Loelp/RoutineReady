import Foundation

// One photo shared from the Photos app, waiting in the Inbox folder.
// The share extension writes these, and the app turns them into maintenance items.
nonisolated struct SharedInboxRecord: Codable, Identifiable, Equatable {
    let id: UUID
    var inspectionID: UUID
    let room: String
    let note: String
    let photoFilename: String   // file name in the Photos folder
    let sharedAt: Date
}

// An inspection you can pick in the share extension (saved in share-inspections.json)
nonisolated struct ShareableInspection: Codable, Identifiable, Equatable {
    let id: UUID
    let address: String
    let scheduledAt: Date
}
