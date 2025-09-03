//
//  InAppMessageExtSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/7/25.
//

import Nimble
import Quick
import UIKit

@testable import Hackle

class InAppMessageExtSpecs: QuickSpec {
    override func spec() {
        describe("InAppMessage supports(orientation:)") {
            it("포함된 orientation이면 true 반환") {
                let msgContext = InAppMessage.MessageContext(
                    defaultLang: "ko",
                    experimentContext: nil,
                    platformTypes: [.ios],
                    orientations: [.vertical, .horizontal],
                    messages: []
                )
                let msg = InAppMessage(
                    id: 1,
                    key: 1,
                    status: .active,
                    period: .always,
                    eventTrigger: InAppMessage.EventTrigger(
                        rules: [],
                        frequencyCap: nil,
                        delay: .init(type: .immediate, afterCondition: nil)
                    ),
                    evaluateContext: .init(atDeliverTime: false),
                    targetContext: InAppMessage.TargetContext(
                        overrides: [],
                        targets: []
                    ),
                    messageContext: msgContext
                )
                expect(msg.supports(orientation: .vertical)).to(beTrue())
                expect(msg.supports(orientation: .horizontal)).to(beTrue())
                expect(msg.supports(platform: .ios)).to(beTrue())
                expect(msg.supports(platform: .android)).to(beFalse())
            }
        }

        describe("InAppMessage.Orientation 생성/지원") {
            it("CGSize, UIInterfaceOrientation, supports(_:) 동작 확인") {
                expect(
                    InAppMessage.Orientation(
                        size: CGSize(width: 100, height: 200)
                    )
                ) == .vertical
                expect(
                    InAppMessage.Orientation(
                        size: CGSize(width: 200, height: 100)
                    )
                ) == .horizontal
                expect(InAppMessage.Orientation(.portrait)) == .vertical
                expect(InAppMessage.Orientation(.landscapeLeft)) == .horizontal
                expect(InAppMessage.Orientation.vertical.supports(.portrait))
                    .to(beTrue())
                expect(InAppMessage.Orientation.horizontal.supports(.portrait))
                    .to(beFalse())
            }
        }

        describe("InAppMessage.Message image(orientation:)") {
            it("지정 orientation의 이미지를 반환") {
                let imgV = InAppMessage.Message.Image(
                    orientation: .vertical,
                    imagePath: "v.png",
                    action: nil
                )
                let imgH = InAppMessage.Message.Image(
                    orientation: .horizontal,
                    imagePath: "h.png",
                    action: nil
                )
                let msg = InAppMessage.Message(
                    variationKey: nil,
                    lang: "ko",
                    layout: InAppMessage.Message.Layout(
                        displayType: .modal,
                        layoutType: .imageText,
                        alignment: nil
                    ),
                    images: [imgV, imgH],
                    imageAutoScroll: nil,
                    text: nil,
                    buttons: [],
                    closeButton: nil,
                    background: InAppMessage.Message.Background(
                        color: "#FFFFFF"
                    ),
                    action: nil,
                    outerButtons: [],
                    innerButtons: []
                )
                expect(msg.image(orientation: .vertical)) === imgV
                expect(msg.image(orientation: .horizontal)) === imgH

            }
        }

        describe("InAppMessage.Message buttonOrNil") {
            it("정렬에 맞는 버튼을 반환") {
                let btn = InAppMessage.Message.Button(
                    text: "ok",
                    style: InAppMessage.Message.Button.Style(
                        textColor: "#000",
                        bgColor: "#fff",
                        borderColor: "#111"
                    ),
                    action: InAppMessage.Action(
                        behavior: .click,
                        type: .close,
                        value: nil
                    )
                )
                let align = InAppMessage.Message.Alignment(
                    vertical: .top,
                    horizontal: .left
                )
                let posBtn = InAppMessage.Message.PositionalButton(
                    button: btn,
                    alignment: align
                )
                let msg = InAppMessage.Message(
                    variationKey: nil,
                    lang: "ko",
                    layout: InAppMessage.Message.Layout(
                        displayType: .modal,
                        layoutType: .imageText,
                        alignment: nil
                    ),
                    images: [],
                    imageAutoScroll: nil,
                    text: nil,
                    buttons: [],
                    closeButton: nil,
                    background: InAppMessage.Message.Background(
                        color: "#FFFFFF"
                    ),
                    action: nil,
                    outerButtons: [],
                    innerButtons: [posBtn]
                )
                expect(msg.buttonOrNil(horizontal: .left, vertical: .top))
                    === posBtn
                expect(msg.buttonOrNil(horizontal: .right, vertical: .bottom))
                    .to(beNil())
            }
        }

        describe("InAppMessage.Message.Button color 확장") {
            it("hex 코드로부터 UIColor 반환") {
                let style = InAppMessage.Message.Button.Style(
                    textColor: "#FF0000",
                    bgColor: "#00FF00",
                    borderColor: "#0000FF"
                )
                let btn = InAppMessage.Message.Button(
                    text: "test",
                    style: style,
                    action: InAppMessage.Action(
                        behavior: .click,
                        type: .close,
                        value: nil
                    )
                )
                expect(btn.textColor) == UIColor(hex: "#FF0000")
                expect(btn.backgroundColor) == UIColor(hex: "#00FF00")
                expect(btn.borderColor) == UIColor(hex: "#0000FF")
            }
        }

        describe("InAppMessage.Message.Text.Attribute") {
            it("color 확장과 attributed 생성 동작") {
                let style = InAppMessage.Message.Text.Style(
                    textColor: "#123456"
                )
                let attr = InAppMessage.Message.Text.Attribute(
                    text: "abc",
                    style: style
                )
                expect(attr.color) == UIColor(hex: "#123456")
                let font = UIFont.systemFont(ofSize: 12)
                let color = UIColor.red
                let attributed = attr.attributed(font: font, color: color)
                expect(attributed.string) == "abc"
            }
        }
    }
}
