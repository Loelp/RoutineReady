import SwiftUI

/// The share sheet form: which inspection, which room, and an optional note.
struct AddToInspectionForm: View {
    let inspections: [ShareableInspection]
    let photoCount: Int
    let onCancel: () -> Void
    let onSave: (ShareableInspection, String, String) -> Void

    static let rooms = ["Kitchen", "Bathroom", "Bedroom", "Living area", "Laundry", "Outdoor", "Garage"]

    @State private var selectedInspectionID: UUID?
    @State private var room = rooms[0]
    @State private var note = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                if inspections.isEmpty {
                    Section {
                        Text("No routine inspections are booked for today. Open RoutineReady to check today's run sheet.")
                    }
                } else {
                    Section {
                        Picker("Inspection", selection: $selectedInspectionID) {
                            ForEach(inspections) { inspection in
                                Text("\(timeText(inspection.scheduledAt)) · \(inspection.address)")
                                    .tag(Optional(inspection.id))
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    } header: {
                        Text("Inspection")
                    }
                    Section("Details") {
                        Picker("Room", selection: $room) {
                            ForEach(Self.rooms, id: \.self) { room in
                                Text(room)
                            }
                        }
                        TextField("Note (optional)", text: $note, axis: .vertical)
                    }
                }
            }
            .navigationTitle(photoCount == 1 ? "Add 1 photo" : "Add \(photoCount) photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            save()
                        }
                        .disabled(selectedInspection == nil)
                    }
                }
            }
            .onAppear {
                if selectedInspectionID == nil {
                    selectedInspectionID = inspections.first?.id
                }
            }
        }
    }

    private var selectedInspection: ShareableInspection? {
        return inspections.first { $0.id == selectedInspectionID }
    }

    private func save() {
        guard let inspection = selectedInspection else { return }
        isSaving = true
        onSave(inspection, room, note.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// Sydney time, e.g. "11:15 am".
    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_AU")
        formatter.timeZone = TimeZone(identifier: "Australia/Sydney")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    AddToInspectionForm(
        inspections: [
            ShareableInspection(id: UUID(), address: "14 Rose St, Yagoona", scheduledAt: Date()),
            ShareableInspection(id: UUID(), address: "21 Wattle St, Punchbowl", scheduledAt: Date().addingTimeInterval(3 * 60 * 60))
        ],
        photoCount: 2,
        onCancel: {},
        onSave: { _, _, _ in }
    )
}
