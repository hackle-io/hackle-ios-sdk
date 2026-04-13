import SwiftUI

struct ExplorerButtonContent: View {
    var body: some View {
        Image("hackle_logo.png", bundle: HackleInternalResources.bundle)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 35, height: 35)
    }
}
