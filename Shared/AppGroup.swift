import Foundation

// Shared folder between the app, the widget and the share extension.
// Only JSON files and photos go in here - the Core Data database stays in the app's own container.
enum AppGroup {
    static let identifier = "group.com.lucas.routineready"

    static var containerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            #if DEBUG
            // if this crashes, the App Group probably isn't ticked in Signing & Capabilities for this target
            fatalError("App Group \(identifier) is not set up for this target")
            #else
            return FileManager.default.temporaryDirectory
            #endif
        }
        return url
    }

    // the app writes this and the widget reads it
    static var widgetSnapshotURL: URL {
        return containerURL.appending(path: "widget-snapshot.json")
    }

    // the app writes this and the share extension reads it (the list of inspections you can pick)
    static var shareInspectionsURL: URL {
        return containerURL.appending(path: "share-inspections.json")
    }

    // defect photos (Core Data only keeps the file name)
    static var photosDirectory: URL {
        return makeFolder(named: "Photos")
    }

    // the share extension saves a SharedInboxRecord file here for each photo
    static var inboxDirectory: URL {
        return makeFolder(named: "Inbox")
    }

    private static func makeFolder(named name: String) -> URL {
        let url = containerURL.appending(path: name, directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

// All three targets read and write the same files, so they all need to use the same date format
enum AppGroupJSON {
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
