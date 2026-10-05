import SwiftUI

// Shared photos that couldn't be filed (e.g. the inspection got cancelled) so they can be moved
struct SharedPhotosInboxView: View {
    @State private var viewModel: SharedPhotosInboxViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(dependencies: AppDependencies) {
        _viewModel = State(initialValue: dependencies.makeSharedPhotosInboxViewModel())
    }

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage = viewModel.errorMessage {
                    ErrorMessageView(message: errorMessage)
                }
                ForEach(viewModel.unfiledPhotos) { photo in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 12) {
                            DefectPhotoThumbnail(filename: photo.record.photoFilename)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(photo.record.note.isEmpty ? "No note" : photo.record.note)
                                Text(photo.record.room)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        ErrorMessageView(message: ErrorMessage(photo.reason))
                        Menu("Choose another inspection") {
                            ForEach(viewModel.todaysInspections) { stop in
                                Button("\(stop.inspection.scheduledAt.inspectionTimeText) · \(stop.property.address)") {
                                    viewModel.reassign(photo, to: stop)
                                }
                            }
                        }
                        .disabled(viewModel.todaysInspections.isEmpty)
                    }
                    .padding(.vertical, 4)
                }
            }
            .overlay {
                if viewModel.unfiledPhotos.isEmpty {
                    ContentUnavailableView(
                        "No photos waiting",
                        systemImage: "tray",
                        description: Text("Photos you share to RoutineReady from the Photos app are filed automatically. Any that can't be filed show up here.")
                    )
                }
            }
            .navigationTitle("Shared Photos")
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

#Preview {
    SharedPhotosInboxView(dependencies: .preview())
}
