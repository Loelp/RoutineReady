import SwiftUI

/// Every property the manager looks after, searchable by address or suburb.
struct PortfolioView: View {
    let dependencies: AppDependencies
    @State private var viewModel: PortfolioViewModel
    @State private var isAddingProperty = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = State(initialValue: dependencies.makePortfolioViewModel())
    }

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage = viewModel.errorMessage {
                    ErrorMessageView(message: errorMessage)
                }
                ForEach(viewModel.properties) { property in
                    NavigationLink(value: property) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(property.address)
                                .font(.headline)
                            Text(property.suburb)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .overlay {
                if viewModel.properties.isEmpty && !viewModel.searchText.isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchText)
                }
            }
            .navigationTitle("Portfolio")
            .searchable(text: $viewModel.searchText, prompt: "Address or suburb")
            .onChange(of: viewModel.searchText) {
                viewModel.load()
            }
            .toolbar {
                Button("Add property", systemImage: "plus") {
                    isAddingProperty = true
                }
            }
            .sheet(isPresented: $isAddingProperty, onDismiss: viewModel.load) {
                AddPropertyView(viewModel: dependencies.makeAddPropertyViewModel())
            }
            .navigationDestination(for: Property.self) { property in
                PropertyDetailView(propertyID: property.id, dependencies: dependencies)
            }
            .navigationDestination(for: RoutineInspection.self) { inspection in
                InspectionInProgressView(inspectionID: inspection.id, dependencies: dependencies)
            }
            .onAppear {
                viewModel.load()
            }
        }
    }
}

#Preview {
    PortfolioView(dependencies: .preview())
}
