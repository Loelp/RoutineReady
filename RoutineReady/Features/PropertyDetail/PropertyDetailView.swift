import SwiftUI

/// One property: who lives there, who owns it, and its routine inspection history.
struct PropertyDetailView: View {
    let dependencies: AppDependencies
    @State private var viewModel: PropertyDetailViewModel
    @State private var isBooking = false

    init(propertyID: UUID, dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: dependencies.makePropertyDetailViewModel(propertyID: propertyID))
    }

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                ErrorMessageView(message: errorMessage)
            }
            if let detail = viewModel.detail {
                Section("Tenancy") {
                    LabeledContent("Tenant", value: detail.property.tenantName)
                    LabeledContent("Landlord", value: detail.property.landlordName)
                    LabeledContent("Tenancy started", value: detail.property.tenancyStartDate.formatted(date: .abbreviated, time: .omitted))
                }

                Section {
                    Text(viewModel.allowanceText)
                    Button("Book routine inspection", systemImage: "calendar.badge.plus") {
                        isBooking = true
                    }
                }

                Section("Inspection history") {
                    if detail.inspectionHistory.isEmpty {
                        Text("No routine inspections yet.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(detail.inspectionHistory) { inspection in
                        if inspection.status == .cancelled {
                            InspectionHistoryRow(inspection: inspection)
                        } else {
                            NavigationLink(value: inspection) {
                                InspectionHistoryRow(inspection: inspection)
                            }
                            .swipeActions {
                                if inspection.status == .scheduled {
                                    Button("Cancel", role: .destructive) {
                                        viewModel.cancel(inspection)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.detail?.property.address ?? "Property")
        .sheet(isPresented: $isBooking, onDismiss: viewModel.load) {
            ScheduleInspectionView(viewModel: dependencies.makeScheduleInspectionViewModel(propertyID: viewModel.propertyID))
        }
        .onAppear {
            viewModel.load()
        }
    }
}

struct InspectionHistoryRow: View {
    let inspection: RoutineInspection

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(inspection.scheduledAt.inspectionDayText) \(inspection.scheduledAt.formatted(.dateTime.year())), \(inspection.scheduledAt.inspectionTimeText)")
                .font(.headline)
            HStack {
                Text(inspection.status.rawValue.capitalized)
                    .foregroundStyle(statusColor)
                if inspection.tenantConsentRecorded {
                    Text("· Tenant agreed in writing")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
            if let summary = inspection.conditionSummary {
                Text(summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statusColor: Color {
        switch inspection.status {
        case .scheduled: return .blue
        case .completed: return .green
        case .cancelled: return .secondary
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    let property = try! dependencies.properties.allProperties().first!
    return NavigationStack {
        PropertyDetailView(propertyID: property.id, dependencies: dependencies)
    }
}
