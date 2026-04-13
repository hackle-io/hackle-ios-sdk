import SwiftUI

struct ExplorerRootView: View {

    @ObservedObject var viewModel: ExplorerViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                headerView
                userInfoSection
                    .padding(.top, 12)
                tabSelector
                    .padding(.top, 12)
                tabContent
            }

            ToastView(message: "Copied")
                .padding(.bottom, 50)
                .opacity(viewModel.showCopiedToast ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: viewModel.showCopiedToast)
        }
        .background(Color(red: 0.949, green: 0.949, blue: 0.949))
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            viewModel.loadUser()
        }
    }

    private var headerView: some View {
        ZStack {
            if let path = HackleInternalResources.bundle.path(forResource: "hackle_banner", ofType: "png"),
               let bannerImage = UIImage(contentsOfFile: path) {
                Image(uiImage: bannerImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 153, height: 20)
            }
            HStack {
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    if let path = HackleInternalResources.bundle.path(forResource: "hackle_cancel", ofType: "png"),
                       let cancelImage = UIImage(contentsOfFile: path) {
                        Image(uiImage: cancelImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    }
                }
                .padding(.trailing, 16)
            }
        }
        .frame(height: 48)
        .background(Color.white)
    }

    private var userInfoSection: some View {
        UserInfoSectionView(viewModel: viewModel)
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "A/B Test", tab: .abTest)
            tabButton(title: "Feature Flag", tab: .featureFlag)
            Spacer()
        }
        .frame(height: 48)
        .background(Color.white)
    }

    private func tabButton(title: String, tab: ExperimentType) -> some View {
        Button(action: {
            viewModel.selectedTab = tab
        }) {
            VStack(spacing: 0) {
                Spacer()
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(viewModel.selectedTab == tab ? .black : Color(UIColor.lightGray))
                Spacer()
                if viewModel.selectedTab == tab {
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 2)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 2)
                }
            }
        }
        .frame(width: 120, height: 48)
    }

    private var tabContent: some View {
        Group {
            if viewModel.selectedTab == .abTest {
                AbTestListView(viewModel: viewModel)
            } else {
                FeatureFlagListView(viewModel: viewModel)
            }
        }
    }
}
