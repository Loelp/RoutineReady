import Foundation

/// Test and SwiftUI preview stand-in for `SharedInboxReader`.
final class InMemorySharedPhotoInbox: SharedPhotoInbox {
    private(set) var records: [SharedInboxRecord]

    init(_ records: [SharedInboxRecord] = []) {
        self.records = records
    }

    func pendingRecords() throws -> [SharedInboxRecord] {
        records.sorted { $0.sharedAt < $1.sharedAt }
    }

    func save(_ record: SharedInboxRecord) throws {
        records.removeAll { $0.id == record.id }
        records.append(record)
    }

    func remove(_ record: SharedInboxRecord) throws {
        records.removeAll { $0.id == record.id }
    }
}
