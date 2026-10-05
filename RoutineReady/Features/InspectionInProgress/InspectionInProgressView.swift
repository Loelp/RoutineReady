import PhotosUI
import SwiftUI

/// The walk-through: log maintenance items room by room, then write the condition summary and complete.
struct InspectionInProgressView: View {
    @State private var viewModel: InspectionInProgressViewModel
    @State private var photoItem: PhotosPickerItem?

    init(inspectionID: UUID, dependencies: AppDependencies) {
        _viewModel = State(initialValue: dependencies.makeInspectionInProgressViewModel(inspectionID: inspectionID))
    }

    var body: some View {
        Form {
            if let loadError = viewModel.loadError {
                ErrorMessageView(message: loadError)
            }
            if let details = viewModel.details {
                Section {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(details.property.address)
                            .font(.title3.bold())
                        Text(details.property.suburb)
                        Text("\(details.inspection.scheduledAt.inspectionDayText), \(details.inspection.scheduledAt.inspectionTimeText) · Tenant: \(details.property.tenantName)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Maintenance items") {
                    if details.maintenanceItems.isEmpty {
                        Text("Nothing logged yet.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(details.maintenanceItems) { item in
                        MaintenanceItemRow(item: item)
                            .swipeActions {
                                if !item.isResolved {
                                    Button("Resolved") {
                                        viewModel.resolve(item)
                                    }
                                    .tint(.green)
                                }
                            }
                    }
                }

                if details.inspection.status != .cancelled {
                    logItemSection
                }

                if viewModel.isCompleted {
                    Section("Condition summary") {
                        Text(details.inspection.conditionSummary ?? "")
                        if let completedAt = details.inspection.completedAt {
                            Text("Completed \(completedAt.inspectionDayText) at \(completedAt.inspectionTimeText)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if details.inspection.status == .scheduled {
                    completeSection
                }
            }
        }
        .navigationTitle("Inspection")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.load()
        }
        .task(id: photoItem) {
            if let photoItem = photoItem {
                viewModel.photoData = try? await photoItem.loadTransferable(type: Data.self)
            }
        }
    }

    private var logItemSection: some View {
        Section("Log maintenance item") {
            TextField("Room", text: $viewModel.room)
            TextField("Description", text: $viewModel.itemDescription, axis: .vertical)
            Picker("Severity", selection: $viewModel.severity) {
                ForEach(MaintenanceSeverity.allCases) { severity in
                    Text(severity.displayName).tag(severity)
                }
            }
            .pickerStyle(.segmented)
            let hasPhoto = viewModel.photoData != nil
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label(hasPhoto ? "Photo attached" : "Add photo", systemImage: hasPhoto ? "checkmark.circle.fill" : "camera")
            }
            if let itemError = viewModel.itemError {
                ErrorMessageView(message: itemError)
            }
            Button("Log item") {
                if viewModel.logItem() {
                    photoItem = nil
                }
            }
        }
    }

    private var completeSection: some View {
        Section("Condition summary") {
            TextField("Overall condition for the landlord's report", text: $viewModel.conditionSummary, axis: .vertical)
                .lineLimit(3...6)
            if let completionError = viewModel.completionError {
                ErrorMessageView(message: completionError)
            }
            Button("Complete inspection") {
                viewModel.complete()
            }
            .bold()
        }
    }
}

struct MaintenanceItemRow: View {
    let item: MaintenanceItem

    var body: some View {
        HStack(spacing: 12) {
            if let filename = item.photoFilename {
                DefectPhotoThumbnail(filename: filename)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.itemDescription)
                    .strikethrough(item.isResolved)
                Text(item.room.isEmpty ? item.severity.displayName : "\(item.room) · \(item.severity.displayName)")
                    .font(.footnote)
                    .foregroundStyle(item.severity == .urgent && !item.isResolved ? .red : .secondary)
            }
            Spacer()
            if item.isResolved {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    let stop = try! dependencies.loadTodaysRunSheet.execute().first!
    return NavigationStack {
        InspectionInProgressView(inspectionID: stop.inspection.id, dependencies: dependencies)
    }
}
