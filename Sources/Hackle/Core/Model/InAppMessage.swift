//
//  InAppMessage.swift
//  Hackle
//
//  Created by yong on 2023/05/31.
//

import Foundation

class InAppMessage: HackleInAppMessage {
    typealias Id = Int64
    typealias Key = Int64

    let id: Id
    let key: Key
    let status: Status
    let period: Period
    let timetable: Timetable
    let eventTrigger: EventTrigger
    let evaluateContext: EvaluateContext
    let targetContext: TargetContext
    let messageContext: MessageContext

    init(
        id: Id,
        key: Key,
        status: Status,
        period: Period,
        timetable: Timetable,
        eventTrigger: EventTrigger,
        evaluateContext: EvaluateContext,
        targetContext: TargetContext,
        messageContext: MessageContext
    ) {
        self.id = id
        self.key = key
        self.status = status
        self.period = period
        self.timetable = timetable
        self.eventTrigger = eventTrigger
        self.evaluateContext = evaluateContext
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
    
    enum Timetable {
        case all
        case custom(slots: [TimetableSlot])
        
        func within(date: Date) -> Bool {
            switch self {
            case .all:
                return true
            case .custom(slots: let slots):
                return slots.contains(where: { $0.within(date: date) })
            }
        }
    }
    
    class TimetableSlot {
        let dayOfWeek: DayOfWeek
        let startMillisInclusive: Int64
        let endMillisExclusive: Int64
        
        init(dayOfWeek: DayOfWeek, startMillisInclusive: Int64, endMillisExclusive: Int64) {
            self.dayOfWeek = dayOfWeek
            self.startMillisInclusive = startMillisInclusive
            self.endMillisExclusive = endMillisExclusive
        }
        
        func within(date: Date) -> Bool {
            guard let dayOfWeek = TimeUtil.dayOfWeek(date) else {
                return false
            }

            if self.dayOfWeek != dayOfWeek {
                return false
            }

            let midnight = TimeUtil.midnight(date)
            let startTimestampInclusive = midnight.addingTimeInterval(TimeInterval(startMillisInclusive) * 0.001)
            let endTimestampExclusive = midnight.addingTimeInterval(TimeInterval(endMillisExclusive) * 0.001)
            let timeRange = startTimestampInclusive..<endTimestampExclusive

            return timeRange.contains(date)
        }
    }

    class EventTrigger {
        let rules: [Rule]
        let frequencyCap: FrequencyCap?
        let delay: Delay

        init(rules: [Rule], frequencyCap: FrequencyCap?, delay: Delay) {
            self.rules = rules
            self.frequencyCap = frequencyCap
            self.delay = delay
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

        class Delay {

            static let `default` = Delay(type: .immediate, afterCondition: nil)

            let type: DelayType
            let afterCondition: AfterCondition?

            init(type: DelayType, afterCondition: AfterCondition?) {
                self.type = type
                self.afterCondition = afterCondition
            }

            func deliverAt(startedAt: Date) -> Date {
                switch type {
                case .immediate:
                    return startedAt
                case .after:
                    return startedAt.addingTimeInterval(afterCondition!.duration)
                }
            }

            class AfterCondition {
                let duration: TimeInterval

                init(duration: TimeInterval) {
                    self.duration = duration
                }
            }
        }
    }

    class EvaluateContext {

        static let `default` = EvaluateContext(atDeliverTime: false)

        let atDeliverTime: Bool

        init(atDeliverTime: Bool) {
            self.atDeliverTime = atDeliverTime
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

    enum DelayType: String, Codable {
        case immediate = "IMMEDIATE"
        case after = "AFTER"
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
        let imageAutoScroll: ImageAutoScroll?
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
            imageAutoScroll: ImageAutoScroll?,
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
            self.imageAutoScroll = imageAutoScroll
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

        class ImageAutoScroll {
            let interval: TimeInterval

            init(interval: TimeInterval) {
                self.interval = interval
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

    class CloseActionInfo: HackleInAppMessageActionClose {
        var hideDuration: TimeInterval

        init(hideDuration: TimeInterval) {
            self.hideDuration = hideDuration
        }
    }

    class LinkActionInfo: HackleInAppMessageActionLink {
        var url: String
        var shouldCloseAfterLink: Bool

        init(url: String, shouldCloseAfterLink: Bool) {
            self.url = url
            self.shouldCloseAfterLink = shouldCloseAfterLink
        }
    }

    class Action: HackleInAppMessageAction {
        let DEFAULT_HIDDEN_TIME_INTERVAL = TimeInterval(60 * 60 * 24) // 24H

        let behavior: Behavior
        let actionType: ActionType
        let value: String?

        var type: HackleInAppMessageActionType {
            switch actionType {
            case .close, .hidden:
                return .close
            case .webLink, .linkAndClose:
                return .link
            }
        }

        var close: HackleInAppMessageActionClose? {
            switch actionType {
            case .close:
                return CloseActionInfo(hideDuration: 0)
            case .hidden:
                return CloseActionInfo(hideDuration: DEFAULT_HIDDEN_TIME_INTERVAL)
            case .webLink, .linkAndClose:
                return nil
            }
        }

        var link: HackleInAppMessageActionLink? {
            switch actionType {
            case .close, .hidden:
                return nil
            case .webLink:
                return LinkActionInfo(url: value ?? "", shouldCloseAfterLink: false)
            case .linkAndClose:
                return LinkActionInfo(url: value ?? "", shouldCloseAfterLink: true)
            }
        }

        init(behavior: Behavior, type: ActionType, value: String?) {
            self.behavior = behavior
            self.actionType = type
            self.value = value
        }
    }
}

extension InAppMessage: CustomStringConvertible {

    var description: String {
        return "InAppMessage(id: \(id), key: \(key), status: \(status))"
    }

    func supports(platform: PlatformType) -> Bool {
        messageContext.platformTypes.contains(platform)
    }
}

extension InAppMessage.Action: CustomStringConvertible {
    var description: String {
        return "InAppMessage.Action(behavior: \(behavior), actionType: \(actionType), value: \(String(describing: value)))"
    }
}
