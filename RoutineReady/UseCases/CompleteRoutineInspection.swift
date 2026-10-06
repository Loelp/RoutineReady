import Foundation

/// Marks an inspection as done. It has to still be scheduled, it has to be the day of the
/// inspection or later, and it needs a condition summary because that goes in the landlord's report.
struct CompleteRoutineInspection {
    let inspections: InspectionRepository
    let clock: DateProviding
    let widgetSnapshot: WidgetSnapshotWriting
    var calendar: Calendar = .sydney

    func execute(inspectionID: UUID, conditionSummary: String) throws -> RoutineInspection {
        guard var inspection = try inspections.inspection(withID: inspectionID) else {
            throw InspectionCompletionError.inspectionNotFound
        }

        if inspection.status == .cancelled {
            throw InspectionCompletionError.inspectionCancelled
        }
        if inspection.status == .completed {
            throw InspectionCompletionError.alreadyCompleted
        }

        let inspectionDay = calendar.startOfDay(for: inspection.scheduledAt)
        let today = calendar.startOfDay(for: clock.now)
        if inspectionDay > today {
            throw InspectionCompletionError.notYetDue
        }

        let summary = conditionSummary.trimmingCharacters(in: .whitespacesAndNewlines)
        if summary.isEmpty {
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
        case .notYetDue:
            return "This inspection is booked for a later day, so it can't be completed yet."
        case .alreadyCompleted:
            return "This inspection has already been completed."
        case .inspectionCancelled:
            return "This inspection was cancelled, so it can't be completed."
        case .missingConditionSummary:
            return "Add a short condition summary before completing — the landlord's report needs it."
        case .inspectionNotFound:
            return "This inspection couldn't be found."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notYetDue:
            return "Complete it on the day of the inspection."
        case .alreadyCompleted:
            return "You can see the report on the property's page."
        case .inspectionCancelled:
            return "Book a new routine inspection from the property's page."
        case .missingConditionSummary:
            return "A sentence or two is fine, e.g. \"Clean and tidy, some wear on the carpets.\""
        case .inspectionNotFound:
            return "Go back to today's run sheet and open it again."
        }
    }
}
