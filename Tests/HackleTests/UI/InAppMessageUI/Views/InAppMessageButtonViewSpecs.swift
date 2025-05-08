//
//  InAppMessageButtonViewSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/7/25.
//

import Quick
import Nimble
import UIKit

@testable import Hackle

class ButtonViewSpecs: QuickSpec {
    override func spec() {
        describe("ButtonView") {
            var button: InAppMessage.Message.Button!
            var sut: HackleInAppMessageUI.ButtonView!
            var attributes: HackleInAppMessageUI.ButtonView.Attributes!

            beforeEach {
                button = InAppMessage.Message.Button(
                    text: "Test Button",
                    style: InAppMessage.Message.Button.Style(textColor: "red", bgColor: "blue", borderColor: "green"),
                    action: InAppMessage.Action(behavior: .click, type: .close, value: nil)
                )
                attributes = .defaults
                sut = HackleInAppMessageUI.ButtonView(button: button, attributes: attributes)
            }

            it("content 세팅이 정상적으로 동작한다") {
                expect(sut.title(for: .normal)) == button.text
                expect(sut.titleColor(for: .normal)) == button.textColor
                expect(sut.backgroundColor) == button.backgroundColor
                expect(sut.layer.borderColor) == button.borderColor.cgColor
                expect(sut.layer.borderWidth) == CGFloat(attributes.borderWidth)
                expect(sut.layer.cornerRadius) == CGFloat(attributes.cornerRadius)
            }

            it("layout 세팅이 정상적으로 동작한다") {
                expect(sut.titleLabel?.lineBreakMode) == NSLineBreakMode.byTruncatingTail
                expect(sut.titleLabel?.adjustsFontSizeToFitWidth) == false
                expect(sut.layer.masksToBounds) == true
                expect(sut.contentEdgeInsets) == attributes.padding
            }

            it("intrinsicContentSize가 minWidth/maxHeight를 반영한다") {
                let size = sut.intrinsicContentSize
                expect(size.width) >= CGFloat(attributes.minWidth)
                expect(size.height) <= CGFloat(attributes.maxHeight)
            }

            it("traitCollectionDidChange 호출 시 content/layout이 재적용된다") {
                sut.traitCollectionDidChange(nil)
                // crash 없이 정상 동작하면 성공
            }
        }
    }
}

class PositionalButtonViewSpecs: QuickSpec {
    override func spec() {
        describe("PositionalButtonView") {
            var button: InAppMessage.Message.Button!
            var alignment: InAppMessage.Message.Alignment!
            var sut: HackleInAppMessageUI.PositionalButtonView!
            var attributes: HackleInAppMessageUI.PositionalButtonView.Attributes!

            beforeEach {
                button = InAppMessage.Message.Button(
                    text: "Test Button",
                    style: InAppMessage.Message.Button.Style(textColor: "red", bgColor: "blue", borderColor: "green"),
                    action: InAppMessage.Action(behavior: .click, type: .close, value: nil)
                )
                alignment = InAppMessage.Message.Alignment(vertical: .top, horizontal: .left)
                attributes = .defaults
                sut = HackleInAppMessageUI.PositionalButtonView(button: button, alignment: alignment, attributes: attributes)
            }

            it("content 세팅이 정상적으로 동작한다") {
                expect(sut.title(for: .normal)) == button.text
                expect(sut.titleColor(for: .normal)) == button.textColor
                expect(sut.titleLabel?.font) == attributes.font
            }

            it("layout 세팅이 정상적으로 동작한다") {
                expect(sut.titleLabel?.lineBreakMode) == NSLineBreakMode.byTruncatingTail
                expect(sut.titleLabel?.adjustsFontSizeToFitWidth) == false
                expect(sut.contentEdgeInsets) == attributes.padding
            }
        }
    }
}
