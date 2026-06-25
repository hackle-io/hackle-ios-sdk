import SwiftUI

struct ExplorerRootView: View {

    @ObservedObject var viewModel: ExplorerViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            headerView
            tabContent
            Spacer()
        }
        .background(Color.explorerBackground)
        .onAppear {
            viewModel.loadUser()
        }
        .adaptiveBottomInset {
            tabSelector
                .padding(.top, 1)
        }
    }

    private var headerView: some View {
        ZStack {
            if let bannerImage = UIImage.hackle(named: "hackle_banner") {
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
                    if let cancelImage = UIImage.hackle(named: "hackle_cancel") {
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

    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "person", tab: .user)
            Spacer()
            tabButton(title: "person.2", tab: .abTest)
            Spacer()
            tabButton(title: "flag", tab: .featureFlag)
            Spacer()
            tabButton(title: "arrow.up.doc", tab: .inAppMessage)
        }
        .frame(height: 24)
        .padding(EdgeInsets(top: 0, leading: 48, bottom: 0, trailing: 48))
        .background(
                Color.white
                    .edgesIgnoringSafeArea(.bottom)
            )
        
    }

    private func tabButton(title: String, tab: ExplorerTab) -> some View {
        Button(action: {
            viewModel.selectedTab = tab
        }) {
            VStack(spacing: 0) {
                if viewModel.selectedTab == tab {
                    Image(systemName: "\(title).fill")
                } else {
                    Image(systemName: title)
                }
                
                
            }
        }
    }

    private var tabContent: some View {
        Group {
            switch viewModel.selectedTab {
            case .user:
                UserInfoSectionView(viewModel: viewModel)
            case .abTest:
                AbTestListView(viewModel: viewModel)
            case .featureFlag:
                FeatureFlagListView(viewModel: viewModel)
            case .inAppMessage:
                InAppMessageListView(viewModel: viewModel)
            }
        }
    }
}

#if DEBUG
class MockUserExplorer: HackleUserExplorer {
    func currentUser() -> HackleUser {
        HackleUser.builder()
            .identifier(.id, "hackle-id")
            .identifier(.device, "hevice-id")
            .identifier(.user, "user-id")
            .properties([
                "string":"string",
                "int":0619,
                "double":123.123,
                "bool": false,
                "array": [1, 2, 3],
                "dict": ["key": "value"],
                "json":"{key:value}"
            ])
            .build()
    }
    
    func registeredPushToken() -> String? {
        "push-token"
    }
    
    func getAbTestDecisions() -> [(any Experiment, Decision)] {
        []
    }
    
    func getAbTestOverrides() -> [Int64 : Int64] {
        [:]
    }
    
    func setAbTestOverride(experiment: any Experiment, variation: any Variation) {
        
    }
    
    func resetAbTestOverride(experiment: any Experiment, variation: any Variation) {
        
    }
    
    func resetAllAbTestOverride() {
        
    }
    
    func getFeatureFlagDecisions() -> [(any Experiment, FeatureFlagDecision)] {
        []
    }
    
    func getInAppMessageDecisions() -> [(InAppMessage, InAppMessageEligibilityEvaluation)] {
        []
    }

    func getFeatureFlagOverrides() -> [Int64 : Int64] {
        [:]
    }
    
    func setFeatureFlagOverride(experiment: any Experiment, variation: any Variation) {
        
    }
    
    func resetFeatureFlagOverride(experiment: any Experiment, variation: any Variation) {
        
    }
    
    func resetAllFeatureFlagOverride() {
        
    }
}

#Preview {
    ExplorerRootView(viewModel: ExplorerViewModel(explorer: MockUserExplorer()))
}
#endif
