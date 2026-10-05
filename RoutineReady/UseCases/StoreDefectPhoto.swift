import UIKit

/// Saves a defect photo taken during an inspection into the App Group `Photos/` folder as a JPEG.
/// Returns the file name, which is all Core Data stores.
struct StoreDefectPhoto {
    let photosDirectory: URL

    func execute(imageData: Data) throws -> String {
        guard let image = UIImage(data: imageData), let jpegData = image.jpegData(compressionQuality: 0.7) else {
            throw DefectPhotoError.unreadablePhoto
        }
        let filename = UUID().uuidString + ".jpg"
        do {
            try jpegData.write(to: photosDirectory.appending(path: filename))
        } catch {
            throw DefectPhotoError.couldNotSave
        }
        return filename
    }
}

enum DefectPhotoError: LocalizedError {
    case unreadablePhoto
    case couldNotSave

    var errorDescription: String? {
        switch self {
        case .unreadablePhoto: return "This photo couldn't be read."
        case .couldNotSave: return "The photo couldn't be saved on this iPhone."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .unreadablePhoto: return "Choose a different photo, or log the item without one."
        case .couldNotSave: return "Check the iPhone has free storage, then try again."
        }
    }
}
