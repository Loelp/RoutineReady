import SwiftUI

struct AddPropertyView: View {
    @State var viewModel: AddPropertyViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Property") {
                    TextField("Street address", text: $viewModel.address)
                    TextField("Suburb", text: $viewModel.suburb)
                }
                Section("Tenancy") {
                    TextField("Tenant", text: $viewModel.tenantName)
                    TextField("Landlord", text: $viewModel.landlordName)
                    DatePicker("Tenancy started", selection: $viewModel.tenancyStartDate, displayedComponents: .date)
                }
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        ErrorMessageView(message: errorMessage)
                    }
                }
            }
            .navigationTitle("Add Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.save() {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    AddPropertyView(viewModel: AppDependencies.preview().makeAddPropertyViewModel())
}
