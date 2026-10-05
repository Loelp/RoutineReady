import Foundation

// Reads the SharedInboxRecord files the share extension puts in the Inbox folder
// (one <id>.json per photo), and deletes them once they've been filed.
class SharedInboxReader: SharedPhotoInbox {
    private let inboxDirectory: URL

    init(inboxDirectory: URL) {
        self.inboxDirectory = inboxDirectory
    }

    func pendingRecords() throws -> [SharedInboxRecord] {
        let files = try FileManager.default.contentsOfDirectory(at: inboxDirectory, includingPropertiesForKeys: nil)
        var records: [SharedInboxRecord] = []
        for file in files where file.pathExtension == "json" {
            // skip anything that doesn't decode instead of failing the whole import
            if let data = try? Data(contentsOf: file),
               let record = try? AppGroupJSON.decode(SharedInboxRecord.self, from: data) {
                records.append(record)
            }
        }
        return records.sorted { $0.sharedAt < $1.sharedAt }
    }

    func save(_ record: SharedInboxRecord) throws {
        try AppGroupJSON.encode(record).write(to: fileURL(for: record), options: .atomic)
    }

    func remove(_ record: SharedInboxRecord) throws {
        try FileManager.default.removeItem(at: fileURL(for: record))
    }

    private func fileURL(for record: SharedInboxRecord) -> URL {
        return inboxDirectory.appending(path: "\(record.id.uuidString).json")
    }
}
