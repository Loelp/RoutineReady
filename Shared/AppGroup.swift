import Foundation

/// The App Group shared by the app, the widget and the share extension.
/// Only small JSON files and photos cross this boundary; the Core Data store stays in the app's own container.
nonisolated enum AppGroup {
    static let identifier = "group.com.lucas.routineready"

    static var containerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            #if DEBUG
            fatalError("App Group \(identifier) is missing from this target's entitlements (Signing & Capabilities).")
            #else
            return FileManager.default.temporaryDirectory
            #endif
        }
        return url
    }

    /// Read by the widget; written by the app after every change.
    static var widgetSnapshotURL: URL { containerURL.appending(path: "widget-snapshot.json") }

    /// Inspections the share extension offers in its picker; written by the app.
    static var shareInspectionsURL: URL { containerURL.appending(path: "share-inspections.json") }

    /// Defect photos, referenced from Core Data by file name only.
    static var photosDirectory: URL { directory(named: "Photos") }

    /// `SharedInboxRecord` JSON files waiting for the app to file them.
    static var inboxDirectory: URL { directory(named: "Inbox") }

    private static func directory(named name: String) -> URL {
        let url = containerURL.appending(path: name, directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

/// One JSON format for every file in the App Group, so all three targets agree on dates.
nonisolated enum AppGroupJSON {
    static func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(value)
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }
}
