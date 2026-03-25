import Foundation

protocol WebResourceLoader {
    func load(url: URL) -> WebResource?
}
