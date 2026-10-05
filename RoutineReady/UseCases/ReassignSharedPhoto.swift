import Foundation

/// Points an unfiled shared photo at a different inspection and tries to file it again.
/// Reports failures with `SharedPhotoImportError`, because it is the same import operation re-attempted.
struct ReassignSharedPhoto {
    let inbox: SharedPhotoInbox
    let importSharedPhotos: ImportSharedPhotos

    @discardableResult
    func execute(record: SharedInboxRecord, toInspectionID inspectionID: UUID) throws -> SharedPhotoImportResult {
        var reassigned = record
        reassigned.inspectionID = inspectionID
        try inbox.save(reassigned)
        return try importSharedPhotos.execute()
    }
}
