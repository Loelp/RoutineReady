import SwiftUI

/// A small square preview of a defect photo stored in the App Group `Photos/` folder.
struct DefectPhotoThumbnail: View {
    let filename: String

    var body: some View {
        let url = AppGroup.photosDirectory.appending(path: filename)
        if let image = UIImage(contentsOfFile: url.path()) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Image(systemName: "photo")
                .frame(width: 56, height: 56)
                .foregroundStyle(.secondary)
        }
    }
}
