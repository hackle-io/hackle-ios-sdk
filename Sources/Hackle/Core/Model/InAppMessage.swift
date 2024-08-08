//
//  InAppMessage.swift
//  Hackle
//
//  Created by yong on 2023/05/31.
//

import Foundation


class InAppMessage {

    typealias Id = Int64
    typealias Key = Int64

    let id: Id
    let key: Key
    let status: Status
    let period: Period
    let eventTrigger: EventTrigger
    let targetContext: TargetContext
    let messageContext: MessageContext

    init(
        id: Id,
        key: Key,
        status: Status,
        period: Period,
        eventTrigger: EventTrigger,
        targetContext: TargetContext,
        messageContext: MessageContext
    ) {
        self.id = id
        self.key = key
        self.status = status
        self.period = period
        self.eventTrigger = eventTrigger
        self.targetContext = targetContext
        self.messageContext = messageContext
    }
}

extension InAppMessage {

    enum Status: String, Codable {
        case initialized = "INITIALIZED"
        case draft = "DRAFT"
        case active = "ACTIVE"
        case pause = "PAUSE"
        case finished = "FINISHED"
    }

    enum Period {
        case always
        case range(startInclusive: Date, endExclusive: Date)

        func within(date: Date) -> Bool {
            switch self {
            case .always:
                return true
            case .range(let startInclusive, let endExclusive):
                return startInclusive <= date && date < endExclusive
            }
        }
    }

    class EventTrigger {

        let rules: [Rule]
        let frequencyCap: FrequencyCap?

        init(rules: [Rule], frequencyCap: FrequencyCap?) {
            self.rules = rules
            self.frequencyCap = frequencyCap
        }

        class Rule {
            let eventKey: String
            let targets: [Target]

            init(eventKey: String, targets: [Target]) {
                self.eventKey = eventKey
                self.targets = targets
            }
        }

        class FrequencyCap {
            let identifierCaps: [IdentifierCap]
            let durationCap: DurationCap?

            init(identifierCaps: [IdentifierCap], durationCap: DurationCap?) {
                self.identifierCaps = identifierCaps
                self.durationCap = durationCap
            }
        }

        class IdentifierCap {
            let identifierType: String
            let count: Int64

            init(identifierType: String, count: Int64) {
                self.identifierType = identifierType
                self.count = count
            }
        }

        class DurationCap {
            let duration: TimeInterval
            let count: Int64

            init(duration: TimeInterval, count: Int64) {
                self.duration = duration
                self.count = count
            }
        }
    }

    class TargetContext {
        let overrides: [UserOverride]
        let targets: [Target]

        init(overrides: [UserOverride], targets: [Target]) {
            self.overrides = overrides
            self.targets = targets
        }
    }

    class UserOverride {
        let identifierType: String
        let identifiers: [String]

        init(identifierType: String, identifiers: [String]) {
            self.identifierType = identifierType
            self.identifiers = identifiers
        }
    }

    enum DisplayType: String, Codable {
        case none = "NONE"
        case modal = "MODAL"
        case banner = "BANNER"
        case bottomSheet = "BOTTOM_SHEET"
    }

    enum LayoutType: String, Codable {
        case none = "NONE"
        case imageText = "IMAGE_TEXT"
        case imageOnly = "IMAGE_ONLY"
        case textOnly = "TEXT_ONLY"
        case image = "IMAGE"
    }

    enum PlatformType: String, Codable {
        case web = "WEB"
        case ios = "IOS"
        case android = "ANDROID"
    }

    enum Orientation: String, Codable {
        case vertical = "VERTICAL"
        case horizontal = "HORIZONTAL"
    }

    enum Behavior: String, Codable {
        case click = "CLICK"
    }

    enum ActionType: String, Codable {
        case close = "CLOSE"
        case webLink = "WEB_LINK"
        case hidden = "HIDDEN"
        case linkAndClose = "LINK_AND_CLOSE"
    }

    enum ActionArea: String, Codable {
        case message = "MESSAGE"
        case image = "IMAGE"
        case button = "BUTTON"
        case xButton = "X_BUTTON"
    }

    enum VerticalAlignment: String, Codable {
        case top = "TOP"
        case middle = "MIDDLE"
        case bottom = "BOTTOM"
    }

    enum HorizontalAlignment: String, Codable {
        case left = "LEFT"
        case center = "CENTER"
        case right = "RIGHT"
    }

    class MessageContext {
        let defaultLang: String
        let experimentContext: ExperimentContext?
        let platformTypes: [PlatformType]
        let orientations: [Orientation]
        let messages: [Message]

        init(
            defaultLang: String,
            experimentContext: ExperimentContext?,
            platformTypes: [PlatformType],
            orientations: [Orientation],
            messages: [Message]
        ) {
            self.defaultLang = defaultLang
            self.experimentContext = experimentContext
            self.platformTypes = platformTypes
            self.orientations = orientations
            self.messages = messages
        }
    }

    class ExperimentContext {
        let key: Int64

        init(key: Int64) {
            self.key = key
        }
    }

    class Message {
        let variationKey: String?
        let lang: String
        let layout: Layout
        let images: [Image]
        let text: Text?
        let buttons: [Button]
        let closeButton: Button?
        let background: Background
        let action: Action?
        let outerButtons: [PositionalButton]
        let innerButtons: [PositionalButton]

        init(
            variationKey: String?,
            lang: String,
            layout: Layout,
            images: [Image],
            text: Text?,
            buttons: [Button],
            closeButton: Button?,
            background: Background,
            action: Action?,
            outerButtons: [PositionalButton],
            innerButtons: [PositionalButton]
        ) {
            self.variationKey = variationKey
            self.lang = lang
            self.layout = layout
            self.images = images
            self.text = text
            self.buttons = buttons
            self.closeButton = closeButton
            self.background = background
            self.action = action
            self.outerButtons = outerButtons
            self.innerButtons = innerButtons
        }

        class Layout {
            let displayType: DisplayType
            let layoutType: LayoutType
            let alignment: Alignment?

            init(displayType: DisplayType, layoutType: LayoutType, alignment: Alignment?) {
                self.displayType = displayType
                self.layoutType = layoutType
                self.alignment = alignment
            }
        }

        class Image {
            let orientation: Orientation
            let imagePath: String
            let action: Action?

            init(orientation: Orientation, imagePath: String, action: Action?) {
                self.orientation = orientation
                self.imagePath = imagePath
                self.action = action
            }
        }

        class Text {
            let title: Attribute
            let body: Attribute

            init(title: Attribute, body: Attribute) {
                self.title = title
                self.body = body
            }

            class Attribute {
                let text: String
                let style: Style

                init(text: String, style: Style) {
                    self.text = text
                    self.style = style
                }
            }

            class Style {
                let textColor: String

                init(textColor: String) {
                    self.textColor = textColor
                }
            }
        }

        class Button {
            let text: String
            let style: Style
            let action: Action

            init(text: String, style: Style, action: Action) {
                self.text = text
                self.style = style
                self.action = action
            }

            class Style {
                let textColor: String
                let bgColor: String
                let borderColor: String

                init(textColor: String, bgColor: String, borderColor: String) {
                    self.textColor = textColor
                    self.bgColor = bgColor
                    self.borderColor = borderColor
                }
            }
        }

        class Background {
            let color: String

            init(color: String) {
                self.color = color
            }
        }

        class Alignment {
            let vertical: VerticalAlignment
            let horizontal: HorizontalAlignment

            init(vertical: VerticalAlignment, horizontal: HorizontalAlignment) {
                self.vertical = vertical
                self.horizontal = horizontal
            }
        }

        class PositionalButton {
            let button: Button
            let alignment: Alignment

            init(button: Button, alignment: Alignment) {
                self.button = button
                self.alignment = alignment
            }
        }
    }

    class Action {
        let behavior: Behavior
        let type: ActionType
        let value: String?

        init(behavior: Behavior, type: ActionType, value: String?) {
            self.behavior = behavior
            self.type = type
            self.value = value
        }
    }
}


extension InAppMessage {
    func supports(platform: PlatformType) -> Bool {
        messageContext.platformTypes.contains(platform)
    }
}