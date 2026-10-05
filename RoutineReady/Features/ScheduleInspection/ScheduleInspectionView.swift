import SwiftUI

// Booking form. If a rule is broken the error shows at the bottom of the form.
struct ScheduleInspectionView: View {
    @State var viewModel: ScheduleInspectionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Inspection") {
                    DatePicker("Date and time", selection: $viewModel.scheduledAt)
                }
                Section {
                    DatePicker("Notice served", selection: $viewModel.noticeServedAt, displayedComponents: .date)
                    Toggle("Tenant has agreed in writing to this time", isOn: $viewModel.tenantConsentRecorded)
                } header: {
                    Text("Notice")
                } footer: {
                    Text("NSW requires 7 days written notice, no more than 4 routine inspections in 12 months, and no Sundays, public holidays or starts outside 8 am to 8 pm. The tenant's written agreement waives everything except the 4-inspection limit.")
                }
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        ErrorMessageView(message: errorMessage)
                    }
                }
            }
            // the rules use Sydney time so the pickers should too
            .environment(\.timeZone, Calendar.sydney.timeZone)
            .navigationTitle("Book Inspection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Book") {
                        if viewModel.book() {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let dependencies = AppDependencies.preview()
    let property = try! dependencies.properties.allProperties().first!
    return ScheduleInspectionView(viewModel: dependencies.makeScheduleInspectionViewModel(propertyID: property.id))
}
