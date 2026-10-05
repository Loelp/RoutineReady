import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// "Add to inspection": files photos shared from the Photos app against one of today's inspections.
/// It only writes to the App Group (photos to `Photos/`, one `SharedInboxRecord` per photo to `Inbox/`)
/// and never touches Core Data. The app files the records as maintenance items when it next becomes active.
class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let form = AddToInspectionForm(
            inspections: loadShareableInspections(),
            photoCount: imageProviders().count,
            onCancel: { [weak self] in
                self?.cancel()
            },
            onSave: { [weak self] inspection, room, note in
                self?.save(to: inspection, room: room, note: note)
            }
        )
        let host = UIHostingController(rootView: form)
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    /// Today's inspections, as last written by the app to `share-inspections.json`.
    private func loadShareableInspections() -> [ShareableInspection] {
        guard let data = try? Data(contentsOf: AppGroup.shareInspectionsURL),
              let inspections = try? AppGroupJSON.decode([ShareableInspection].self, from: data) else {
            return []
        }
        return inspections
    }

    /// The shared attachments that are images (the activation rule allows up to 10).
    private func imageProviders() -> [NSItemProvider] {
        var providers: [NSItemProvider] = []
        let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        for item in items {
            for provider in item.attachments ?? [] where provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                providers.append(provider)
            }
        }
        return providers
    }

    private func save(to inspection: ShareableInspection, room: String, note: String) {
        Task {
            for provider in imageProviders() {
                guard let data = await loadImageData(from: provider),
                      let jpegData = UIImage(data: data)?.jpegData(compressionQuality: 0.7) else {
                    continue
                }
                let record = SharedInboxRecord(
                    id: UUID(),
                    inspectionID: inspection.id,
                    room: room,
                    note: note,
                    photoFilename: UUID().uuidString + ".jpg",
                    sharedAt: Date()
                )
                do {
                    try jpegData.write(to: AppGroup.photosDirectory.appending(path: record.photoFilename))
                    let recordURL = AppGroup.inboxDirectory.appending(path: "\(record.id.uuidString).json")
                    try AppGroupJSON.encode(record).write(to: recordURL, options: .atomic)
                } catch {
                    print("Could not save shared photo: \(error)")
                }
            }
            // Always dismiss, even if a photo could not be read.
            extensionContext?.completeRequest(returningItems: nil)
        }
    }

    private func cancel() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)
        extensionContext?.cancelRequest(withError: error)
    }

    private func loadImageData(from provider: NSItemProvider) async -> Data? {
        return await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                continuation.resume(returning: data)
            }
        }
    }
}
