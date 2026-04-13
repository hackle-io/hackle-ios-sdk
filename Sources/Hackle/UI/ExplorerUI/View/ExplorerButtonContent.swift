import SwiftUI

struct ExplorerButtonContent: View {
    var body: some View {
        if let uiImage = UIImage(named: "hackle_logo.png", in: HackleInternalResources.bundle, compatibleWith: nil) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 35, height: 35)
        }
    }
}
