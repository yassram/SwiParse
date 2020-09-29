//
//  Associativity.swift
//  SwiParse
//
//  Created by Yassir Ramdani on 08/11/2020.
//  Copyright © 2020 Yassir Ramdani. All rights reserved.
//

import Foundation
import SwiLex

extension SwiParse {
    /// Used to set a left or right associativity for a given token.
    ///
    /// `.left` associativity is translated to a reduce preference while the `.right` associativity privileges a shift.
    ///
    /// # Example:
    ///
    /// The following rule is *ambiguous*.
    ///
    /// ```
    /// let rule = .expression => [Word(.expression), Word(.plus), Word(.expression)]
    /// ```
    /// In fact the parser can not choose between a shift or a reduce for "`1 + 2 + 3`" as an input string.
    ///
    /// This input can be computed as:
    /// - "`(1 + 2) + 3`" (left associativity: **reduction**)
    /// -  "`1 + (2 + 3)`"  (right associativity: **shift**)
    ///
    /// This situation is called a shift / reduce conflict.
    ///
    /// There are many options to solve a shift / reduce conflict.
    ///
    /// # Solution:
    ///
    /// In this example we can set a `.left` associativity to `.plus` by adding `.left(.plus)` to the parser's priority list.
    ///
    /// - Note: The best approach to solve shift / reduce conflicts is to remove the ambiguity of the grammar.
    ///
    /// Setting a precedence order or a associativity may lead to undesired behaviours by silencing some conflicts with a forced order.
    public enum Associative {
        /// Sets a left associativity for the terminal token.
        case left(Terminal)
        /// Sets a right associativity for the terminal token.
        case right(Terminal)

        internal var token: Terminal {
            switch self {
            case let .left(token):
                return token
            case let .right(token):
                return token
            }
        }
    }
}
