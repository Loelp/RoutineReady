import Foundation

/// Turns photos shared from the Photos app (through the share extension) into maintenance items.
/// Each photo becomes one routine item on the inspection that was picked, and its inbox record is deleted.
/// If that inspection has been cancelled (or deleted) since, the photo stays in the inbox
/// so the user can move it to another inspection.
struct ImportSharedPhotos {
    // used when the photo was shared without a note
    static let defaultDescription = "Defect photo shared from Photos"

    let inbox: SharedPhotoInbox
    let logMaintenanceItem: LogMaintenanceItem

    @discardableResult
    func execute() throws -> SharedPhotoImportResult {
        var result = SharedPhotoImportResult()

        for record in try inbox.pendingRecords() {
            var description = record.note
            if description.isEmpty {
                description = ImportSharedPhotos.defaultDescription
            }

            do {
                try logMaintenanceItem.execute(
                    inspectionID: record.inspectionID,
                    room: record.room,
                    description: description,
                    severity: .routine,
                    photoFilename: record.photoFilename
                )
                try inbox.remove(record)
                result.importedCount += 1
            } catch MaintenanceLoggingError.inspectionCancelled, MaintenanceLoggingError.inspectionNotFound {
                // leave it in the inbox for the user to sort out
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

// A shared photo that couldn't be filed and is waiting in the inbox
struct UnfiledSharedPhoto: Identifiable, Equatable {
    let record: SharedInboxRecord
    let reason: SharedPhotoImportError

    var id: UUID {
        return record.id
    }
}

enum SharedPhotoImportError: LocalizedError, Equatable {
    case inspectionNoLongerAvailable

    var errorDescription: String? {
        return "These photos were shared to an inspection that has since been cancelled."
    }

    var recoverySuggestion: String? {
        return "Choose another inspection."
    }
}
