//
//  Item.swift
//  SwiParse
//
//  Created by Yassir Ramdani on 29/09/2020.
//  Copyright © 2020 Yassir Ramdani. All rights reserved.
//

import Foundation

extension SwiParse {
    struct Item: Hashable {
        /// The item's rule.
        let rule: Rule
        /// The item's position in the rule.
        let index: Int
        /// The lookahead terminal token of the item.
        let follow: Terminal

        /// The nth next word if any,
        /// - Parameter n: the next's position.
        /// - Returns: The nth next word if any or nil.
        func next(_ n: Int = 0) -> DefinedWord? {
            guard index + n < rule.right.count else { return nil }
            return rule.right[index + n]
        }
    }
}

// MARK: Description

extension SwiParse.Item: CustomStringConvertible {
    public var description: String {
        var ruleWithPosition = ""
        for (i, word) in rule.right.enumerated() {
            if i == index { ruleWithPosition += "•" }
            ruleWithPosition += "\(word)"
        }
        if index == rule.right.count { ruleWithPosition += "•" }
        return "[\(rule.left) -> \(ruleWithPosition), \(follow)]"
    }
}
