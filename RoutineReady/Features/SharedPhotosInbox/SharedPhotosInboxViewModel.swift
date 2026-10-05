import Foundation
import Observation

@MainActor
@Observable
class SharedPhotosInboxViewModel {
    var unfiledPhotos: [UnfiledSharedPhoto] = []
    var todaysInspections: [RunSheetStop] = []
    var errorMessage: ErrorMessage?

    private let importSharedPhotos: ImportSharedPhotos
    private let reassignSharedPhoto: ReassignSharedPhoto
    private let loadTodaysRunSheet: LoadTodaysRunSheet

    init(importSharedPhotos: ImportSharedPhotos, reassignSharedPhoto: ReassignSharedPhoto, loadTodaysRunSheet: LoadTodaysRunSheet) {
        self.importSharedPhotos = importSharedPhotos
        self.reassignSharedPhoto = reassignSharedPhoto
        self.loadTodaysRunSheet = loadTodaysRunSheet
    }

    // runs the import - whatever is left over gets shown on screen
    func load() {
        do {
            unfiledPhotos = try importSharedPhotos.execute().unfiled
            todaysInspections = try loadTodaysRunSheet.execute()
            errorMessage = nil
        } catch {
            errorMessage = ErrorMessage(error)
        }
    }

    func reassign(_ photo: UnfiledSharedPhoto, to stop: RunSheetStop) {
        do {
            unfiledPhotos = try reassignSharedPhoto.execute(record: photo.record, toInspectionID: stop.inspection.id).unfiled
            errorMessage = nil
        } catch {
            errorMessage = ErrorMessage(error)
        }
    }
}
