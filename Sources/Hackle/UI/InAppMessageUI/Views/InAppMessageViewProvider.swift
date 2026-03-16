import Foundation

protocol InAppMessageViewProvider {
    @MainActor var currentView: InAppMessageView? { get }
    @MainActor func getView(viewId: String) -> InAppMessageView?
}
