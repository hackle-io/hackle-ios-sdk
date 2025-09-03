import Foundation

extension InAppMessage {
    enum Event {
        case impression
        case close
        case action(
            action: Action,
            area: ActionArea,
            button: Message.Button?,
            image: Message.Image?,
            imageOrder: Int?
        )
        case imageImpression(
            image: InAppMessage.Message.Image,
            order: Int
        )

        static func buttonAction(action: Action, button: InAppMessage.Message.Button) -> Event {
            .action(action: action, area: .button, button: button, image: nil, imageOrder: nil)
        }

        static func imageAction(action: Action, image: InAppMessage.Message.Image, order: Int?) -> Event {
            .action(action: action, area: .image, button: nil, image: image, imageOrder: order)
        }

        static func closeButtonAction(action: Action) -> Event {
            .action(action: action, area: .xButton, button: nil, image: nil, imageOrder: nil)
        }

        static func messageAction(action: Action) -> Event {
            .action(action: action, area: .message, button: nil, image: nil, imageOrder: nil)
        }
    }
}

extension InAppMessage.Event: CustomStringConvertible {
    var description: String {
        switch self {
        case .impression:
            return "InAppMessageEvent.Impression"
        case .close:
            return "InAppMessageEvent.Close"
        case .action(let action, let area, _, _, _):
            return "InAppMessageEvent.Action(action: \(action), area: \(area))"
        case .imageImpression(_, let order):
            return "InAppMessageEvent.ImageImpression(order: \(order))"
        }
    }
}
