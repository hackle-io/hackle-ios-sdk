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
        evaluateContext: EvaluateContext = evaluateContext(),
        targetContext: TargetContext = targetContext(),
        messageContext: MessageContext = messageContext()
    ) -> InAppMessage {
        InAppMessage(
            id: id,
            key: key,
            status: status,
            period: period,
            eventTrigger: eventTrigger,
            evaluateContext: evaluateContext,
            targetContext: targetContext,
            messageContext: messageContext
        )
    }

    static func eventTrigger(
        rules: [InAppMessage.EventTrigger.Rule] = [
            InAppMessage.EventTrigger.Rule(eventKey: "test", targets: [])
        ],
        frequencyCap: InAppMessage.EventTrigger.FrequencyCap? = nil,
        delay: InAppMessage.EventTrigger.Delay = delay()
    ) -> InAppMessage.EventTrigger {
        InAppMessage.EventTrigger(
            rules: rules,
            frequencyCap: frequencyCap,
            delay: delay
        )
    }

    static func frequencyCap(
        identifierCaps: [InAppMessage.EventTrigger.IdentifierCap] = [],
        durationCap: InAppMessage.EventTrigger.DurationCap? = nil
    ) -> InAppMessage.EventTrigger.FrequencyCap {
        InAppMessage.EventTrigger.FrequencyCap(
            identifierCaps: identifierCaps,
            durationCap: durationCap
        )
    }

    static func delay(
        type: InAppMessage.DelayType = .immediate,
        afterCondition: InAppMessage.EventTrigger.Delay.AfterCondition? = nil
    ) -> InAppMessage.EventTrigger.Delay {
        return InAppMessage.EventTrigger.Delay(
            type: type,
            afterCondition: afterCondition
        )
    }

    static func identifierCap(
        identifierType: String = "$id",
        count: Int64 = 1
    ) -> InAppMessage.EventTrigger.IdentifierCap {
        InAppMessage.EventTrigger.IdentifierCap(
            identifierType: identifierType,
            count: count
        )
    }

    static func durationCap(
        duration: TimeInterval = 60,
        count: Int64 = 1
    ) -> InAppMessage.EventTrigger.DurationCap {
        InAppMessage.EventTrigger.DurationCap(duration: duration, count: count)
    }

    static func evaluateContext(
        atDeliverTime: Bool = false
    ) -> InAppMessage.EvaluateContext {
        return EvaluateContext(atDeliverTime: atDeliverTime)
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
            title: Message.Text.Attribute(
                text: title,
                style: Message.Text.Style(textColor: titleColor)
            ),
            body: Message.Text.Attribute(
                text: body,
                style: Message.Text.Style(textColor: bodyColor)
            )
        )
    }

    static func eligibilityRequest(
        workspace: Workspace = MockWorkspace(),
        user: HackleUser = HackleUser.builder().identifier(.id, "user").build(),
        inAppMessage: InAppMessage = create(),
        timestamp: Date = Date()
    ) -> InAppMessageEligibilityRequest {
        InAppMessageEligibilityRequest(
            workspace: workspace,
            user: user,
            inAppMessage: inAppMessage,
            timestamp: timestamp
        )
    }

    static func layoutRequest(
        workspace: Workspace = MockWorkspace(),
        user: HackleUser = HackleUser.builder().identifier(.id, "user").build(),
        inAppMessage: InAppMessage = create()
    ) -> InAppMessageLayoutRequest {
        return InAppMessageLayoutRequest(
            workspace: workspace,
            user: user,
            inAppMessage: inAppMessage
        )
    }

    static func layoutEvaluation(
        request: InAppMessageLayoutRequest = layoutRequest(),
        reason: String = DecisionReason.IN_APP_MESSAGE_TARGET,
        targetEvaluations: [EvaluatorEvaluation] = [],
        message: InAppMessage.Message = message(),
        properties: [String: Any] = [:]
    ) -> InAppMessageLayoutEvaluation {
        return InAppMessageLayoutEvaluation(
            request: request,
            reason: reason,
            targetEvaluations: targetEvaluations,
            message: message,
            properties: properties
        )
    }

    static func eligibilityEvaluation(
        reason: String = DecisionReason.IN_APP_MESSAGE_TARGET,
        targetEvaluations: [EvaluatorEvaluation] = [],
        inAppMessage: InAppMessage = create(),
        isEligible: Bool = true,
        layoutEvaluation: InAppMessageLayoutEvaluation? = nil
    ) -> InAppMessageEligibilityEvaluation {
        InAppMessageEligibilityEvaluation(
            reason: reason,
            targetEvaluations: targetEvaluations,
            inAppMessage: inAppMessage,
            isEligible: isEligible,
            layoutEvaluation: layoutEvaluation
        )
    }

    static func context(
        dispatchId: String = UUID().uuidString,
        inAppMessage: InAppMessage = .create(),
        message: InAppMessage.Message = InAppMessage.message(),
        user: HackleUser = HackleUser.builder().identifier(.id, "user").build(),
        decisionReason: String = DecisionReason.DEFAULT_RULE,
        properties: [String: Any] = [:]
    ) -> InAppMessagePresentationContext {
        return InAppMessagePresentationContext(
            dispatchId: dispatchId,
            inAppMessage: inAppMessage,
            message: message,
            user: user,
            decisionReasion: decisionReason,
            properties: properties
        )
    }

    static func presentRequest(
        dispatchId: String = UUID().uuidString,
        inAppMessage: InAppMessage = InAppMessage.create(),
        message: InAppMessage.Message = InAppMessage.message(),
        user: HackleUser = HackleUser.builder().identifier(.id, "user").build(),
        requestedAt: Date = Date(),
        reason: String = DecisionReason.IN_APP_MESSAGE_TARGET,
        properties: [String: Any] = [:]
    ) -> InAppMessagePresentRequest {
        return InAppMessagePresentRequest(
            dispatchId: dispatchId,
            inAppMessage: inAppMessage,
            message: message,
            user: user,
            requestedAt: requestedAt,
            reason: reason,
            properties: properties
        )
    }

    static func presentResponse(
        dispatchId: String = UUID().uuidString,
        context: InAppMessagePresentationContext = InAppMessage.context()
    ) -> InAppMessagePresentResponse {
        return InAppMessagePresentResponse(
            dispatchId: dispatchId,
            context: context
        )
    }

    static func deliverRequest(
        dispatchId: String = UUID().uuidString,
        inAppMessageKey: InAppMessage.Key = 1,
        identifiers: Identifiers = [
            IdentifierType.device.rawValue: "device_id"
        ],
        requestedAt: Date = Date(),
        reason: String = DecisionReason.IN_APP_MESSAGE_TARGET,
        properties: [String: Any] = [:]
    ) -> InAppMessageDeliverRequest {
        return InAppMessageDeliverRequest(
            dispatchId: dispatchId,
            inAppMessageKey: inAppMessageKey,
            identifiers: identifiers,
            requestedAt: requestedAt,
            reason: reason,
            properties: properties
        )
    }

    static func schedule(
        dispatchId: String = UUID().uuidString,
        inAppMessageKey: InAppMessage.Key = 1,
        identifiers: Identifiers = [
            IdentifierType.device.rawValue: "device_id"
        ],
        time: InAppMessageSchedule.Time = InAppMessageSchedule.Time(
            startedAt: Date(),
            deliverAt: Date()
        ),
        reason: String = DecisionReason.IN_APP_MESSAGE_TARGET,
        eventBasedContext: InAppMessageSchedule.EventBasedContext =
        InAppMessageSchedule.EventBasedContext(
            insertId: UUID().uuidString,
            event: HackleEventBuilder(key: "test").build()
        )
    ) -> InAppMessageSchedule {
        return InAppMessageSchedule(
            dispatchId: dispatchId,
            inAppMessageKey: inAppMessageKey,
            identifiers: identifiers,
            time: time,
            reason: reason,
            eventBasedContext: eventBasedContext
        )
    }

    static func scheduleRequest(
        schedule: InAppMessageSchedule = schedule(),
        scheduleType: InAppMessageScheduleType = .triggered,
        requetedAt: Date = Date()
    ) -> InAppMessageScheduleRequest {
        return InAppMessageScheduleRequest(
            schedule: schedule,
            scheduleType: scheduleType,
            requestedAt: requetedAt
        )
    }

    static func deliverResponse(
        dispatchId: String = UUID().uuidString,
        inAppMessageKey: InAppMessage.Key = 1,
        code: InAppMessageDeliverResponse.Code = .present,
        presentResponse: InAppMessagePresentResponse? = nil
    ) -> InAppMessageDeliverResponse {
        return InAppMessageDeliverResponse(
            dispatchId: dispatchId,
            inAppMessageKey: inAppMessageKey,
            code: code,
            presentResponse: presentResponse
        )
    }
}
