//
//  InAppMessageTestExt.swift
//  HackleTests
//
//  Created by yong on 2023/06/25.
//

import Foundation
@testable import Hackle

extension InAppMessage {

    static func create(
        id: Id = 1,
        key: Key = 1,
        status: Status = .active,
        period: Period = .always,
        eventTrigger: EventTrigger = eventTrigger(),
        targetContext: TargetContext = targetContext(),
        messageContext: MessageContext = messageContext()
    ) -> InAppMessage {
        InAppMessage(
            id: id,
            key: key,
            status: status,
            period: period,
            eventTrigger: eventTrigger,
            targetContext: targetContext,
            messageContext: messageContext
        )
    }

    static func eventTrigger(
        rules: [InAppMessage.EventTrigger.Rule] = [InAppMessage.EventTrigger.Rule(eventKey: "test", targets: [])],
        frequencyCap: InAppMessage.EventTrigger.FrequencyCap? = nil
    ) -> InAppMessage.EventTrigger {
        InAppMessage.EventTrigger(rules: rules, frequencyCap: frequencyCap)
    }

    static func frequencyCap(
        identifierCaps: [InAppMessage.EventTrigger.IdentifierCap] = [],
        durationCap: InAppMessage.EventTrigger.DurationCap? = nil
    ) -> InAppMessage.EventTrigger.FrequencyCap {
        InAppMessage.EventTrigger.FrequencyCap(identifierCaps: identifierCaps, durationCap: durationCap)
    }

    static func identifierCap(
        identifierType: String = "$id",
        count: Int64 = 1
    ) -> InAppMessage.EventTrigger.IdentifierCap {
        InAppMessage.EventTrigger.IdentifierCap(identifierType: identifierType, count: count)
    }

    static func durationCap(
        duration: TimeInterval = 60,
        count: Int64 = 1
    ) -> InAppMessage.EventTrigger.DurationCap {
        InAppMessage.EventTrigger.DurationCap(duration: duration, count: count)
    }

    static func targetContext(
        overrides: [UserOverride] = [],
        targets: [Target] = []
    ) -> TargetContext {
        TargetContext(overrides: overrides, targets: targets)
    }

    static func messageContext(
        defaultLang: String = "ko",
        experimentContext: ExperimentContext? = nil,
        platformTypes: [PlatformType] = [.ios],
        orientations: [Orientation] = [.vertical],
        messages: [Message] = [message()]
    ) -> MessageContext {
        MessageContext(
            defaultLang: defaultLang,
            experimentContext: experimentContext,
            platformTypes: platformTypes,
            orientations: orientations,
            messages: messages
        )
    }

    static func message(
        variationKey: String? = nil,
        lang: String = "ko",
        images: [Message.Image] = [image()],
        imageAutoScroll: Message.ImageAutoScroll? = nil,
        text: Message.Text? = text(),
        buttons: [Message.Button] = [button()],
        closeButton: Message.Button? = nil
    ) -> Message {
        Message(
            variationKey: variationKey,
            lang: lang,
            layout: Message.Layout(
                displayType: .modal,
                layoutType: .imageOnly,
                alignment: nil
            ),
            images: images,
            imageAutoScroll: imageAutoScroll,
            text: text,
            buttons: buttons,
            closeButton: closeButton,
            background: Message.Background(color: "#FFFFFF"),
            action: nil,
            outerButtons: [],
            innerButtons: []
        )
    }

    static func action(
        behavior: Behavior = .click,
        type: ActionType = .close,
        value: String? = nil
    ) -> Action {
        Action(
            behavior: behavior,
            type: type,
            value: value
        )
    }

    static func button(
        text: String = "button",
        textColor: String = "#000000",
        bgColor: String = "#FFFFFF",
        borderColor: String = "#FFFFFF",
        action: Action = action()
    ) -> Message.Button {
        Message.Button(
            text: text,
            style: Message.Button.Style(
                textColor: textColor,
                bgColor: bgColor,
                borderColor: borderColor
            ),
            action: action
        )
    }

    static func image(
        orientation: Orientation = .vertical,
        imagePath: String = "image_path",
        action: Action? = nil
    ) -> Message.Image {
        Message.Image(
            orientation: orientation,
            imagePath: imagePath,
            action: action
        )
    }

    static func text(
        title: String = "title",
        titleColor: String = "#000000",
        body: String = "body",
        bodyColor: String = "#FFFFFF"
    ) -> Message.Text {
        Message.Text(
            title: Message.Text.Attribute(text: title, style: Message.Text.Style(textColor: titleColor)),
            body: Message.Text.Attribute(text: body, style: Message.Text.Style(textColor: bodyColor))
        )
    }

    static func request(
        workspace: Workspace = MockWorkspace(),
        user: HackleUser = HackleUser.builder().identifier(.id, "user").build(),
        inAppMessage: InAppMessage = create(),
        timestamp: Date = Date()
    ) -> InAppMessageRequest {
        InAppMessageRequest(workspace: workspace, user: user, inAppMessage: inAppMessage, timestamp: timestamp)
    }

    static func evaluation(
        reason: String = DecisionReason.IN_APP_MESSAGE_TARGET,
        targetEvaluations: [EvaluatorEvaluation] = [],
        inAppMessage: InAppMessage = create(),
        message: InAppMessage.Message? = nil,
        properties: [String: Any] = [:]
    ) -> InAppMessageEvaluation {
        InAppMessageEvaluation(reason: reason, targetEvaluations: targetEvaluations, inAppMessage: inAppMessage, message: message, properties: properties)
    }

    static func context(
        inAppMessage: InAppMessage = .create(),
        message: InAppMessage.Message = InAppMessage.message(),
        user: HackleUser = HackleUser.builder().identifier(.id, "user").build(),
        properties: [String: Any] = [:],
        decisionReason: String = DecisionReason.DEFAULT_RULE
    ) -> InAppMessagePresentationContext {
        InAppMessagePresentationContext(inAppMessage: inAppMessage, message: message, user: user, properties: properties, decisionReasion: decisionReason)
    }
}
