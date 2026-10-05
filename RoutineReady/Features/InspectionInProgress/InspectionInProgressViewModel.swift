import Foundation
import Observation

@MainActor
@Observable
class InspectionInProgressViewModel {
    var details: InspectionInProgress?
    var loadError: ErrorMessage?

    // New maintenance item
    var room = ""
    var itemDescription = ""
    var severity = MaintenanceSeverity.routine
    var photoData: Data?
    var itemError: ErrorMessage?

    // Completing the inspection
    var conditionSummary = ""
    var completionError: ErrorMessage?

    private let inspectionID: UUID
    private let loadInspection: LoadInspectionInProgress
    private let logMaintenanceItem: LogMaintenanceItem
    private let storeDefectPhoto: StoreDefectPhoto
    private let resolveMaintenanceItem: ResolveMaintenanceItem
    private let completeRoutineInspection: CompleteRoutineInspection

    init(inspectionID: UUID, loadInspection: LoadInspectionInProgress, logMaintenanceItem: LogMaintenanceItem,
         storeDefectPhoto: StoreDefectPhoto, resolveMaintenanceItem: ResolveMaintenanceItem,
         completeRoutineInspection: CompleteRoutineInspection) {
        self.inspectionID = inspectionID
        self.loadInspection = loadInspection
        self.logMaintenanceItem = logMaintenanceItem
        self.storeDefectPhoto = storeDefectPhoto
        self.resolveMaintenanceItem = resolveMaintenanceItem
        self.completeRoutineInspection = completeRoutineInspection
    }

    var isCompleted: Bool {
        return details?.inspection.status == .completed
    }

    func load() {
        do {
            details = try loadInspection.execute(inspectionID: inspectionID)
            loadError = nil
        } catch {
            loadError = ErrorMessage(error)
        }
    }

    /// Returns true if the item was logged, so the view can clear the chosen photo.
    func logItem() -> Bool {
        do {
            var photoFilename: String? = nil
            if let photoData = photoData {
                photoFilename = try storeDefectPhoto.execute(imageData: photoData)
            }
            try logMaintenanceItem.execute(inspectionID: inspectionID, room: room, description: itemDescription,
                                           severity: severity, photoFilename: photoFilename)
            room = ""
            itemDescription = ""
            severity = .routine
            photoData = nil
            itemError = nil
            load()
            return true
        } catch {
            itemError = ErrorMessage(error)
            return false
        }
    }

    func resolve(_ item: MaintenanceItem) {
        do {
            try resolveMaintenanceItem.execute(itemID: item.id)
            load()
        } catch {
            itemError = ErrorMessage(error)
        }
    }

    func complete() {
        do {
            try completeRoutineInspection.execute(inspectionID: inspectionID, conditionSummary: conditionSummary)
            completionError = nil
            load()
        } catch {
            completionError = ErrorMessage(error)
        }
    }
}
