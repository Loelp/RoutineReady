import SwiftUI
import UIKit
import UniformTypeIdentifiers

// "Add to inspection" share extension.
// It only saves files into the App Group (the photo into Photos, and a SharedInboxRecord into Inbox)
// and never touches Core Data. The app picks them up and makes the maintenance items next time it opens.
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

    // today's inspections, from the list the app saved
    private func loadShareableInspections() -> [ShareableInspection] {
        guard let data = try? Data(contentsOf: AppGroup.shareInspectionsURL),
              let inspections = try? AppGroupJSON.makeDecoder().decode([ShareableInspection].self, from: data) else {
            return []
        }
        return inspections
    }

    // the images that were shared (Info.plist limits it to 10)
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
                    try AppGroupJSON.makeEncoder().encode(record).write(to: recordURL, options: .atomic)
                } catch {
                    print("Could not save shared photo: \(error)")
                }
            }
            // close the sheet no matter what, even if one of the photos didn't work
            extensionContext?.completeRequest(returningItems: nil)
        }
    }

    private func cancel() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)
        extensionContext?.cancelRequest(withError: error)
    }

    // loadDataRepresentation uses a completion handler, so this wraps it to use with await
    private func loadImageData(from provider: NSItemProvider) async -> Data? {
        return await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                continuation.resume(returning: data)
            }
        }
    }
}
