//
//  Rule.swift
//  SwiParse
//
//  Created by Yassir Ramdani on 29/09/2020.
//  Copyright © 2020 Yassir Ramdani. All rights reserved.
//

import SwiLex

infix operator >>>>: AdditionPrecedence

public typealias ReductionAction = ([Any]) -> Any

extension SwiParse {
    /// Rules that are used to build a **SwiParse** grammar.
    public struct Rule {
        /// A non terminal token. The result of the reduction using this rule.
        public let left: NonTerminal
        /// A list of Words. The tokens reduced by this rule.
        public let right: [DefinedWord]
        /// The action to be done to reduce the tokens `right` into `left`.
        public var action: ReductionAction

        /// The last terminal token in the rule, if any.
        internal var lastTerminal: DefinedWord? {
            for i in stride(from: right.count - 1, through: 0, by: -1) {
                if case .terminal = right[i] { return right[i] }
            }
            return nil
        }

        /// Defines a rule.
        ///
        /// Rules are used to build a grammar.
        ///
        /// - Parameters:
        ///   - left: A non terminal token. The result of the reduction using this rule.
        ///   - right: A list of Words. The tokens reduced by this rule.
        ///   - action: The action to be done to reduce the tokens `right` into `left`.
        ///
        /// - Note: Operators `=>` and ` >>>>`  are overloaded for more concise syntax.
        public init(_ left: NonTerminal, _ right: [Word<Terminal, NonTerminal>], _ action: @escaping ReductionAction) {
            self.left = left
            self.right = right
            self.action = action
        }

        public static func >>>> (lhs: Self, rhs: @escaping () -> Any) -> Self {
            let act = { (data: [Any]) in rhs() }
            return Rule(lhs.left, lhs.right, act)
        }

        public static func >>>> <U>(lhs: Self, rhs: @escaping (U) -> Any) -> Self {
            let act = { (data: [Any]) in rhs(data[0] as! U) }
            return Rule(lhs.left, lhs.right, act)
        }

        public static func >>>> <U, V>(lhs: Self, rhs: @escaping (U, V) -> Any) -> Self {
            let act = { (data: [Any]) in rhs(data[0] as! U, data[1] as! V) }
            return Rule(lhs.left, lhs.right, act)
        }

        public static func >>>> <U, V, W>(lhs: Self, rhs: @escaping (U, V, W) -> Any) -> Self {
            let act = { (data: [Any]) in rhs(data[0] as! U, data[1] as! V, data[2] as! W) }
            return Rule(lhs.left, lhs.right, act)
        }

        public static func >>>> <U, V, W, Z>(lhs: Self, rhs: @escaping (U, V, W, Z) -> Any) -> Self {
            let act = { (data: [Any]) in rhs(data[0] as! U, data[1] as! V, data[2] as! W, data[3] as! Z) }
            return Rule(lhs.left, lhs.right, act)
        }

        public static func >>>> <U, V, W, Z, A>(lhs: Self, rhs: @escaping (U, V, W, Z, A) -> Any) -> Self {
            let act = { (data: [Any]) in rhs(data[0] as! U, data[1] as! V, data[2] as! W, data[3] as! Z, data[4] as! A) }
            return Rule(lhs.left, lhs.right, act)
        }

        public static func >>>> <U, V, W, Z, A, B>(lhs: Self, rhs: @escaping (U, V, W, Z, A, B) -> Any) -> Self {
            let act = { (data: [Any]) in rhs(data[0] as! U, data[1] as! V, data[2] as! W, data[3] as! Z, data[4] as! A, data[5] as! B) }
            return Rule(lhs.left, lhs.right, act)
        }

        public static func >>>> <U, V, W, Z, A, B, C>(lhs: Self, rhs: @escaping (U, V, W, Z, A, B, C) -> Any) -> Self {
            let act = { (data: [Any]) in rhs(data[0] as! U, data[1] as! V, data[2] as! W, data[3] as! Z, data[4] as! A, data[5] as! B, data[6] as! C) }
            return Rule(lhs.left, lhs.right, act)
        }

        public static func >>>> <U, V, W, Z, A, B, C, D>(lhs: Self, rhs: @escaping (U, V, W, Z, A, B, C, D) -> Any) -> Self {
            let act = { (data: [Any]) in rhs(data[0] as! U, data[1] as! V, data[2] as! W, data[3] as! Z,
                                             data[4] as! A, data[5] as! B, data[6] as! C, data[7] as! D) }
            return Rule(lhs.left, lhs.right, act)
        }

        public static func >>>> <U, V, W, Z, A, B, C, D, E>(lhs: Self, rhs: @escaping (U, V, W, Z, A, B, C, D, E) -> Any) -> Self {
            let act = { (data: [Any]) in rhs(data[0] as! U, data[1] as! V, data[2] as! W, data[3] as! Z, data[4] as! A,
                                             data[5] as! B, data[6] as! C, data[7] as! D, data[8] as! E) }
            return Rule(lhs.left, lhs.right, act)
        }

        public static func >>>> <U, V, W, Z, A, B, C, D, E, F>(lhs: Self, rhs: @escaping (U, V, W, Z, A, B, C, D, E, F) -> Any) -> Self {
            let act = { (data: [Any]) in rhs(data[0] as! U, data[1] as! V, data[2] as! W, data[3] as! Z, data[4] as! A,
                                             data[5] as! B, data[6] as! C, data[7] as! D, data[8] as! E, data[9] as! F) }
            return Rule(lhs.left, lhs.right, act)
        }
    }
}

// MARK: Description

extension SwiParse.Rule: CustomStringConvertible {
    public var description: String {
        "\(left)->\(right.map { "\($0)" }.joined())"
    }
}

// MARK: Hashable

extension SwiParse.Rule: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.left == rhs.left && lhs.right.count == rhs.right.count
            && !((0 ..< lhs.right.count).map { lhs.right[$0] == rhs.right[$0] }).contains(false)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(left)
        hasher.combine(right)
    }
}
