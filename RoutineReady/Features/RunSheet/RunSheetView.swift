import SwiftUI

/// Home tab: today's routine inspections in the order the property manager will visit them.
struct RunSheetView: View {
    let dependencies: AppDependencies
    @State private var viewModel: RunSheetViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: dependencies.makeRunSheetViewModel())
    }

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage = viewModel.errorMessage {
                    ErrorMessageView(message: errorMessage)
                }
                ForEach(viewModel.stops) { stop in
                    NavigationLink(value: stop.inspection) {
                        RunSheetRow(stop: stop)
                    }
                }
            }
            .overlay {
                if viewModel.stops.isEmpty && viewModel.errorMessage == nil {
                    ContentUnavailableView("No routine inspections booked for today.", systemImage: "calendar")
                }
            }
            .navigationTitle("Today's Run Sheet")
            .navigationDestination(for: RoutineInspection.self) { inspection in
                InspectionInProgressView(inspectionID: inspection.id, dependencies: dependencies)
            }
            .onAppear {
                viewModel.load()
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    viewModel.load()
                }
            }
        }
    }
}

struct RunSheetRow: View {
    let stop: RunSheetStop

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(stop.inspection.scheduledAt.inspectionTimeText)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(stop.property.address)
                    .font(.headline)
                Text(stop.property.suburb)
                    .foregroundStyle(.secondary)
                Text("Tenant: \(stop.property.tenantName)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RunSheetView(dependencies: .preview())
}
