import Foundation

/// Photos received from the share extension and not yet filed as maintenance items.
protocol SharedPhotoInbox {
    func pendingRecords() throws -> [SharedInboxRecord]
    /// Inserts or updates, e.g. after the user reassigns a photo to another inspection.
    func save(_ record: SharedInboxRecord) throws
    /// Removes the record only; its photo now belongs to a maintenance item.
    func remove(_ record: SharedInboxRecord) throws
}
