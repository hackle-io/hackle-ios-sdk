import SwiftUI

struct ExplorerButtonContent: View {
    var body: some View {
        if let path = HackleInternalResources.bundle.path(forResource: "hackle_logo", ofType: "png"),
           let uiImage = UIImage(contentsOfFile: path) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 35, height: 35)
        }
    }
}
