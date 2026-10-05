import Foundation

// Photos sent over from the share extension that haven't been filed yet
protocol SharedPhotoInbox {
    func pendingRecords() throws -> [SharedInboxRecord]
    // used when the user moves a photo to a different inspection
    func save(_ record: SharedInboxRecord) throws
    // only deletes the record - the photo file is kept because the maintenance item uses it now
    func remove(_ record: SharedInboxRecord) throws
}
