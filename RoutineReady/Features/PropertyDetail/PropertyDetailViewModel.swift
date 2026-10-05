import Foundation
import Observation

@MainActor
@Observable
class PropertyDetailViewModel {
    var detail: PropertyDetail?
    var errorMessage: ErrorMessage?

    let propertyID: UUID
    private let loadPropertyDetail: LoadPropertyDetail
    private let cancelRoutineInspection: CancelRoutineInspection

    init(propertyID: UUID, loadPropertyDetail: LoadPropertyDetail, cancelRoutineInspection: CancelRoutineInspection) {
        self.propertyID = propertyID
        self.loadPropertyDetail = loadPropertyDetail
        self.cancelRoutineInspection = cancelRoutineInspection
    }

    // e.g. "2 of 4 routine inspections used in the last 12 months"
    var allowanceText: String {
        let used = detail?.inspectionsUsedInLast12Months ?? 0
        return "\(used) of \(RoutineInspectionRules.annualLimit) routine inspections used in the last 12 months"
    }

    func load() {
        do {
            detail = try loadPropertyDetail.execute(propertyID: propertyID)
            errorMessage = nil
        } catch {
            errorMessage = ErrorMessage(error)
        }
    }

    func cancel(_ inspection: RoutineInspection) {
        do {
            try cancelRoutineInspection.execute(inspectionID: inspection.id)
            load()
        } catch {
            errorMessage = ErrorMessage(error)
        }
    }
}
