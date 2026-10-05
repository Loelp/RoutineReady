import SwiftUI

// the three tabs
struct RootTabView: View {
    let dependencies: AppDependencies

    var body: some View {
        TabView {
            Tab("Run Sheet", systemImage: "list.bullet.clipboard") {
                RunSheetView(dependencies: dependencies)
            }
            Tab("Portfolio", systemImage: "house") {
                PortfolioView(dependencies: dependencies)
            }
            Tab("Shared Photos", systemImage: "photo.on.rectangle") {
                SharedPhotosInboxView(dependencies: dependencies)
            }
        }
    }
}

#Preview {
    RootTabView(dependencies: .preview())
}
