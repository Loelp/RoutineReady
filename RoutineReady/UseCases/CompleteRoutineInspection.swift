import Foundation

/// Marks a routine inspection as done. Only a scheduled inspection that is due (today or earlier) can be completed,
/// and it needs a condition summary because the landlord's inspection report is built from it.
struct CompleteRoutineInspection {
    let inspections: InspectionRepository
    let clock: DateProviding
    let widgetSnapshot: WidgetSnapshotWriting
    var calendar: Calendar = .sydney

    @discardableResult
    func execute(inspectionID: UUID, conditionSummary: String) throws -> RoutineInspection {
        guard var inspection = try inspections.inspection(withID: inspectionID) else {
            throw InspectionCompletionError.inspectionNotFound
        }
        switch inspection.status {
        case .cancelled: throw InspectionCompletionError.inspectionCancelled
        case .completed: throw InspectionCompletionError.alreadyCompleted
        case .scheduled: break
        }
        guard calendar.startOfDay(for: inspection.scheduledAt) <= calendar.startOfDay(for: clock.now) else {
            throw InspectionCompletionError.notYetDue
        }
        let summary = conditionSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !summary.isEmpty else {
            throw InspectionCompletionError.missingConditionSummary
        }

        inspection.status = .completed
        inspection.conditionSummary = summary
        inspection.completedAt = clock.now
        try inspections.save(inspection)
        widgetSnapshot.refreshWidgetSnapshot()
        return inspection
    }
}

enum InspectionCompletionError: LocalizedError, Equatable {
    case notYetDue
    case alreadyCompleted
    case inspectionCancelled
    case missingConditionSummary
    case inspectionNotFound

    var errorDescription: String? {
        switch self {
        case .notYetDue: "This inspection is booked for a later day, so it can't be completed yet."
        case .alreadyCompleted: "This inspection has already been completed."
        case .inspectionCancelled: "This inspection was cancelled, so it can't be completed."
        case .missingConditionSummary: "Add a short condition summary before completing — the landlord's report needs it."
        case .inspectionNotFound: "This inspection is no longer in your diary."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notYetDue: "Complete it on the day of the inspection."
        case .alreadyCompleted: "Open the property to see the completed report."
        case .inspectionCancelled: "Book a new routine inspection from the property's page."
        case .missingConditionSummary: "Describe the overall condition in a sentence or two, e.g. \"Clean and well kept; minor wear to carpets.\""
        case .inspectionNotFound: "Go back to today's run sheet and choose the inspection again."
        }
    }
}
