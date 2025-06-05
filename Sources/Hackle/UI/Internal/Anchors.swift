//
//  Anchors.swift
//  Hackle
//
//  Created by yong on 2023/06/15.
//

import Foundation
import UIKit

protocol LayoutItem {
    var superview: UIView? { get }
}

extension UIView: LayoutItem {
}

extension UILayoutGuide: LayoutItem {
    var superview: UIView? {
        owningView
    }
}

extension LayoutItem {
    var anchors: Anchors<Self> {
        Anchors(item: self)
    }
}

struct Anchors<Item: LayoutItem> {
    let item: Item
}

extension Anchors {

    var leading: Anchor<Item, NSLayoutXAxisAnchor> {
        Anchor(item, .leading)
    }

    var trailing: Anchor<Item, NSLayoutXAxisAnchor> {
        Anchor(item, .trailing)
    }

    var left: Anchor<Item, NSLayoutXAxisAnchor> {
        Anchor(item, .left)
    }

    var right: Anchor<Item, NSLayoutXAxisAnchor> {
        Anchor(item, .right)
    }

    var top: Anchor<Item, NSLayoutYAxisAnchor> {
        Anchor(item, .top)
    }

    var bottom: Anchor<Item, NSLayoutYAxisAnchor> {
        Anchor(item, .bottom)
    }

    var width: Anchor<Item, NSLayoutDimension> {
        Anchor(item, .width)
    }

    var height: Anchor<Item, NSLayoutDimension> {
        Anchor(item, .height)
    }

    var centerX: Anchor<Item, NSLayoutXAxisAnchor> {
        Anchor(item, .centerX)
    }

    var centerY: Anchor<Item, NSLayoutYAxisAnchor> {
        Anchor(item, .centerY)
    }

    var leadingMargin: Anchor<Item, NSLayoutXAxisAnchor> {
        Anchor(item, .leadingMargin)
    }

    var trailingMargin: Anchor<Item, NSLayoutXAxisAnchor> {
        Anchor(item, .trailingMargin)
    }

    var leftMargin: Anchor<Item, NSLayoutXAxisAnchor> {
        Anchor(item, .leftMargin)
    }

    var rightMargin: Anchor<Item, NSLayoutXAxisAnchor> {
        Anchor(item, .rightMargin)
    }

    var topMargin: Anchor<Item, NSLayoutYAxisAnchor> {
        Anchor(item, .topMargin)
    }

    var bottomMargin: Anchor<Item, NSLayoutYAxisAnchor> {
        Anchor(item, .bottomMargin)
    }

    var size: AnchorSize<Item> {
        AnchorSize(anchors: self)
    }
}

enum AnchorAxis {
    case vertical, horizontal
}

struct AnchorAlignment {

    let horizontal: Horizontal
    let vertical: Vertical

    static let fill = AnchorAlignment(horizontal: .fill, vertical: .fill)
    static let center = AnchorAlignment(horizontal: .center, vertical: .center)
    static let leading = AnchorAlignment(horizontal: .leading, vertical: .fill)
    static let trailing = AnchorAlignment(horizontal: .trailing, vertical: .fill)
    static let top = AnchorAlignment(horizontal: .fill, vertical: .top)
    static let bottom = AnchorAlignment(horizontal: .fill, vertical: .bottom)

    enum Horizontal {
        case fill, leading, center, trailing
    }

    enum Vertical {
        case fill, top, center, bottom
    }
}

struct AnchorSize<Item: LayoutItem> {
    private let anchors: Anchors<Item>

    init(anchors: Anchors<Item>) {
        self.anchors = anchors
    }

    @discardableResult
    func equal(_ size: CGSize) -> [NSLayoutConstraint] {
        [
            anchors.width.equal(size.width),
            anchors.height.equal(size.height)
        ]
    }

    @discardableResult
    func aspectRatio(_ size: CGSize) -> NSLayoutConstraint {
        anchors.width.equal(anchors.height.multiply(by: size.aspectRatio))
    }
}

extension Anchors where Item: UIView {

    @discardableResult
    func pin(
        to item2: LayoutItem? = nil,
        insets: UIEdgeInsets = .zero,
        axis: AnchorAxis? = nil,
        alignment: AnchorAlignment = .fill,
        priority: UILayoutPriority = .required
    ) -> [NSLayoutConstraint] {
        constraints(to: item2, insets: insets, axis: axis, alignment: alignment, priority: priority)
    }

    @discardableResult
    func lessThanOrEqual(
        to item2: LayoutItem? = nil,
        insets: UIEdgeInsets = .zero,
        axis: AnchorAxis? = nil,
        priority: UILayoutPriority = .required
    ) -> [NSLayoutConstraint] {
        constraints(to: item2, insets: insets, axis: axis, alignment: .center, priority: priority)
    }

    private func constraints(
        to item2: LayoutItem?,
        insets: UIEdgeInsets,
        axis: AnchorAxis?,
        alignment: AnchorAlignment,
        priority: UILayoutPriority
    ) -> [NSLayoutConstraint] {
        let item2 = item2 ?? item.superview!
        var constraints = [NSLayoutConstraint]()

        func constrain(
            attribute: NSLayoutConstraint.Attribute,
            relation: NSLayoutConstraint.Relation,
            constant: CGFloat
        ) {
            let constraint = Constraints.activate(
                item: item,
                attribute: attribute,
                relatedBy: relation,
                toItem: item2,
                attribute: attribute,
                multiplier: 1,
                constant: constant,
                priority: priority
            )
            constraints.append(constraint)
        }

        if axis == nil || axis == .horizontal {
            let horizontal = alignment.horizontal
            constrain(
                attribute: .leading,
                relation: horizontal == .fill || horizontal == .leading ? .equal : .greaterThanOrEqual,
                constant: insets.left
            )
            constrain(
                attribute: .trailing,
                relation: horizontal == .fill || horizontal == .trailing ? .equal : .lessThanOrEqual,
                constant: -insets.right
            )
        }

        if axis == nil || axis == .vertical {
            let vertical = alignment.vertical
            constrain(
                attribute: .top,
                relation: vertical == .fill || vertical == .top ? .equal : .greaterThanOrEqual,
                constant: insets.top
            )
            constrain(
                attribute: .bottom,
                relation: vertical == .fill || vertical == .bottom ? .equal : .lessThanOrEqual,
                constant: -insets.bottom
            )
        }

        return constraints
    }
}

private extension NSLayoutConstraint.Relation {
    var negate: NSLayoutConstraint.Relation {
        switch self {
        case .lessThanOrEqual:
            return .greaterThanOrEqual
        case .equal:
            return .equal
        case .greaterThanOrEqual:
            return .lessThanOrEqual
        @unknown default:
            return self
        }
    }
}

struct Anchor<Item: LayoutItem, Delegate> {
    let item: Item
    let attribute: NSLayoutConstraint.Attribute
    let offset: CGFloat
    let multiplier: CGFloat

    init(
        _ item: Item,
        _ attribute: NSLayoutConstraint.Attribute,
        offset: CGFloat = 0,
        multiplier: CGFloat = 1
    ) {
        self.item = item
        self.attribute = attribute
        self.offset = offset
        self.multiplier = multiplier
    }

    func multiply(by multiplier: CGFloat) -> Anchor {
        Anchor(item, attribute, offset: offset * multiplier, multiplier: self.multiplier * multiplier)
    }
}

extension Anchor {

    @discardableResult
    func equal<T: LayoutItem, D>(
        _ other: Anchor<T, D>,
        constant: CGFloat = 0
    ) -> NSLayoutConstraint {
        Constraints.activate(self, other, constant: constant, relation: .equal)
    }

    @discardableResult
    func greaterThanOrEqual<T: LayoutItem, D>(
        _ other: Anchor<T, D>,
        constant: CGFloat = 0
    ) -> NSLayoutConstraint {
        Constraints.activate(self, other, constant: constant, relation: .greaterThanOrEqual)
    }

    @discardableResult
    func lessThanOrEqual<T: LayoutItem, D>(
        _ other: Anchor<T, D>,
        constant: CGFloat = 0
    ) -> NSLayoutConstraint {
        Constraints.activate(self, other, constant: constant, relation: .lessThanOrEqual)
    }
}

// Dimension

extension Anchor where Delegate: NSLayoutDimension {

    @discardableResult
    func equal(_ constant: CGFloat) -> NSLayoutConstraint {
        Constraints.activate(item: item, attribute: attribute, relatedBy: .equal, constant: constant)
    }

    @discardableResult
    func greaterThanOrEqual(_ constant: CGFloat) -> NSLayoutConstraint {
        Constraints.activate(item: item, attribute: attribute, relatedBy: .greaterThanOrEqual, constant: constant)
    }

    @discardableResult
    func lessThanOrEqual(_ constant: CGFloat) -> NSLayoutConstraint {
        Constraints.activate(item: item, attribute: attribute, relatedBy: .lessThanOrEqual, constant: constant)
    }
}

// XAxisAnchor

extension Anchor where Delegate: NSLayoutXAxisAnchor {

    @discardableResult
    func pin(to container: LayoutItem? = nil, inset: CGFloat = 0) -> NSLayoutConstraint {
        let negative = [NSLayoutConstraint.Attribute.trailing, NSLayoutConstraint.Attribute.right, NSLayoutConstraint.Attribute.bottom].contains(attribute)
        return Constraints.activate(self, toItem: container ?? item.superview!, attribute: attribute, constant: (negative ? -inset : inset))
    }

    @discardableResult
    func align(offset: CGFloat = 0) -> NSLayoutConstraint {
        Constraints.activate(self, toItem: item.superview!, attribute: attribute, constant: offset)
    }
}

// YAxisAnchor

extension Anchor where Delegate: NSLayoutYAxisAnchor {

    @discardableResult
    func pin(to container: LayoutItem? = nil, inset: CGFloat = 0) -> NSLayoutConstraint {
        let negative = [NSLayoutConstraint.Attribute.trailing, NSLayoutConstraint.Attribute.right, NSLayoutConstraint.Attribute.bottom].contains(attribute)
        return Constraints.activate(self, toItem: container ?? item.superview!, attribute: attribute, constant: (negative ? -inset : inset))
    }

    @discardableResult
    func align(offset: CGFloat = 0) -> NSLayoutConstraint {
        Constraints.activate(self, toItem: item.superview!, attribute: attribute, constant: offset)
    }
}

// Constraint

class Constraints {

    private var constraints = [NSLayoutConstraint]()

    @discardableResult
    init(_ block: () -> ()) {
        Constraints.constraints.append(self)
        block()
        Constraints.constraints.removeLast()
        NSLayoutConstraint.activate(constraints)
    }

    func add(_ constraint: NSLayoutConstraint) {
        constraints.append(constraint)
    }

    func activate() {
        NSLayoutConstraint.activate(constraints)
    }

    func deactivate() {
        NSLayoutConstraint.deactivate(constraints)
    }

    private static var constraints = [Constraints]()

    private static func activate(_ constraint: NSLayoutConstraint) {
        if let constrains = constraints.last {
            constrains.add(constraint)
        } else {
            constraint.isActive = true
        }
    }

    @discardableResult
    static func activate(
        item item1: Any,
        attribute attr1: NSLayoutConstraint.Attribute,
        relatedBy relation: NSLayoutConstraint.Relation = .equal,
        toItem item2: Any? = nil,
        attribute attr2: NSLayoutConstraint.Attribute? = nil,
        multiplier: CGFloat = 1,
        constant: CGFloat = 0,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {
        (item1 as? UIView)?.translatesAutoresizingMaskIntoConstraints = false
        let constraint = NSLayoutConstraint(
            item: item1,
            attribute: attr1,
            relatedBy: relation,
            toItem: item2,
            attribute: attr2 ?? .notAnAttribute,
            multiplier: multiplier,
            constant: constant
        )
        constraint.priority = priority
        activate(constraint)
        return constraint
    }

    @discardableResult
    static func activate<T1: LayoutItem, D1, T2: LayoutItem, D2>(
        _ anchor: Anchor<T1, D1>,
        _ anchor2: Anchor<T2, D2>,
        constant: CGFloat = 0,
        multiplier: CGFloat = 1,
        relation: NSLayoutConstraint.Relation = .equal
    ) -> NSLayoutConstraint {
        activate(
            item: anchor.item,
            attribute: anchor.attribute,
            relatedBy: relation,
            toItem: anchor2.item,
            attribute: anchor2.attribute,
            multiplier: (multiplier / anchor.multiplier) * anchor2.multiplier,
            constant: constant - anchor.offset + anchor2.offset
        )
    }

    @discardableResult
    static func activate<T: LayoutItem, D>(
        _ anchor: Anchor<T, D>,
        toItem item2: Any?,
        attribute attr2: NSLayoutConstraint.Attribute?,
        constant: CGFloat = 0,
        multiplier: CGFloat = 1,
        relation: NSLayoutConstraint.Relation = .equal
    ) -> NSLayoutConstraint {
        activate(
            item: anchor.item,
            attribute: anchor.attribute,
            relatedBy: relation,
            toItem: item2,
            attribute: attr2,
            multiplier: multiplier / anchor.multiplier,
            constant: constant - anchor.offset
        )
    }
}
