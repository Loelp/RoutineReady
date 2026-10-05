import Foundation

/// Files photos shared from the Photos app (through the share extension) as maintenance items.
/// Each inbox record becomes one routine-severity item on the inspection the user picked, and is then removed.
/// A record whose inspection has since been cancelled or deleted stays in the inbox so the user can reassign it.
struct ImportSharedPhotos {
    static let defaultDescription = "Defect photo shared from Photos"

    let inbox: SharedPhotoInbox
    let logMaintenanceItem: LogMaintenanceItem

    @discardableResult
    func execute() throws -> SharedPhotoImportResult {
        var result = SharedPhotoImportResult()
        for record in try inbox.pendingRecords() {
            do {
                try logMaintenanceItem.execute(
                    inspectionID: record.inspectionID,
                    room: record.room,
                    description: record.note.isEmpty ? Self.defaultDescription : record.note,
                    severity: .routine,
                    photoFilename: record.photoFilename
                )
                try inbox.remove(record)
                result.importedCount += 1
            } catch MaintenanceLoggingError.inspectionCancelled, MaintenanceLoggingError.inspectionNotFound {
                result.unfiled.append(UnfiledSharedPhoto(record: record, reason: .inspectionNoLongerAvailable))
            }
        }
        return result
    }
}

struct SharedPhotoImportResult: Equatable {
    var importedCount = 0
    var unfiled: [UnfiledSharedPhoto] = []
}

/// A shared photo that stays in the inbox until the user picks another inspection for it.
struct UnfiledSharedPhoto: Identifiable, Equatable {
    let record: SharedInboxRecord
    let reason: SharedPhotoImportError

    var id: UUID { record.id }
}

enum SharedPhotoImportError: LocalizedError, Equatable {
    case inspectionNoLongerAvailable

    var errorDescription: String? {
        "These photos were shared to an inspection that has since been cancelled."
    }

    var recoverySuggestion: String? {
        "Choose another inspection."
    }
}
