//
//  SwiParsable.swift
//  SwiParse
//
//  Created by Yassir Ramdani on 11/10/2020.
//  Copyright © 2020 Yassir Ramdani. All rights reserved.
//

import Foundation
import SwiLex

/// A type of tokens that are used as non terminal tokens of a **SwiParse** grammar.
public protocol SwiParsable: Hashable, CaseIterable {
    /// The starting rule of the grammar.
    static var start: Self { get }
}

infix operator =>: MultiplicationPrecedence

public extension SwiParsable {

    /// Operator overloading for better readability and concise Rule definition.
    /// 
    /// - Parameters:
    ///   - lhs: A non terminal token. The result of the reduction using this rule.
    ///   - rhs: A list of Words. The tokens reduced by this rule.
    /// - Returns: A rule that reduces rhs tokens into a non terminal token lhs.
    ///
    /// # Example
    ///
    /// ```
    ///  .exp => [Word(.number), Word(.plus), Word(.number)]
    ///  // A rule that produces an expression by reducing a `.number`, `.plus` and `.number` tokens.
    ///
    /// ```
    static func => <T: SwiLexable>(lhs: Self, rhs: [Word<T, Self>]) -> SwiParse<T, Self>.Rule {
        return SwiParse<T, Self>.Rule(lhs, rhs) { _ in }
    }
}
