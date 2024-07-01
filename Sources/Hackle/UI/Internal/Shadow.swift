import Foundation
import UIKit

struct Shadow: Equatable {
    let color: UIColor
    let offset: CGSize
    let radius: CGFloat
    let opacity: Float

    static let inAppMessage = Shadow(
        color: .black.withAlphaComponent(0.3),
        offset: CGSize(width: 0, height: 2),
        radius: 4, opacity: 0.5
    )
}
