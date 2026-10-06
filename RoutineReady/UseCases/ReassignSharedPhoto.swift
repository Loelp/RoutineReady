import Foundation

/// Moves a photo that couldn't be filed onto a different inspection, then tries the import again.
/// It doesn't have its own error enum - it's really just the import being run again,
/// so it uses SharedPhotoImportError.
struct ReassignSharedPhoto {
    let inbox: SharedPhotoInbox
    let importSharedPhotos: ImportSharedPhotos

    func execute(record: SharedInboxRecord, toInspectionID inspectionID: UUID) throws -> SharedPhotoImportResult {
        var updatedRecord = record
        updatedRecord.inspectionID = inspectionID
        try inbox.save(updatedRecord)
        return try importSharedPhotos.execute()
    }
}
