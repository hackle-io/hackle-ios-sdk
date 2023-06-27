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
        triggerRules: [TriggerRule] = [TriggerRule(eventKey: "test", targets: [])],
        targetContext: TargetContext = target(),
        messageContext: MessageContext = context()
    ) -> InAppMessage {
        InAppMessage(
            id: id,
            key: key,
            status: status,
            period: period,
            triggerRules: triggerRules,
            targetContext: targetContext,
            messageContext: messageContext
        )
    }

    static func target(
        overrides: [UserOverride] = [],
        targets: [Target] = []
    ) -> TargetContext {
        TargetContext(overrides: overrides, targets: targets)
    }

    static func context(
        defaultLang: String = "ko",
        platformTypes: [PlatformType] = [.ios],
        messages: [Message] = [message()]
    ) -> MessageContext {
        MessageContext(
            defaultLang: defaultLang,
            platformTypes: platformTypes,
            messages: messages
        )
    }

    static func message(
        lang: String = "ko",
        images: [Message.Image] = [image()],
        text: Message.Text? = text(),
        buttons: [Message.Button] = [button()],
        closeButton: Message.Button? = nil
    ) -> Message {
        Message(
            lang: lang,
            layout: Message.Layout(
                displayType: .modal,
                layoutType: .imageOnly
            ),
            images: images,
            text: text,
            buttons: buttons,
            closeButton: closeButton,
            background: Message.Background(color: "#FFFFFF")
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
        message: InAppMessage.Message? = nil
    ) -> InAppMessageEvaluation {
        InAppMessageEvaluation(reason: reason, targetEvaluations: targetEvaluations, inAppMessage: inAppMessage, message: message)
    }
}
