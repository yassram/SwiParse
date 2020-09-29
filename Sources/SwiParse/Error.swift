//
//  Error.swift
//  SwiParse
//
//  Created by Yassir Ramdani on 09/11/2020.
//  Copyright © 2020 Yassir Ramdani. All rights reserved.
//

import Foundation
import SwiLex

extension SwiParse {
    public enum ParseError: Error {
        // Grammar sanity.
        case emptyRuleDefined
        case multipleStartingRulesDefined
        case noStartingRuleDefined

        // Parsing errors
        case parsingError([DefinedWord], Token<Terminal>)

        // Ambiguous grammar.
        case AmbiguousGrammar(String, String)
        case shiftReduceConflict(DefinedWord, String)
    }
}

extension SwiParse.ParseError : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .shiftReduceConflict(word, action):
            return "Ambiguous grammar:\nSHIFT/REDUCE conflict\nConflict between shift[\(word)] and \(action)"
        case let .parsingError(expected, found):
            return "Parsing error. Expected: \(expected), found: \(found)"
        case .multipleStartingRulesDefined:
            return "Rules should have a single starting rule"
        case .noStartingRuleDefined:
            return "Rules should have a starting rule"
        case let .AmbiguousGrammar(firstAction, secondAction):
            return "Ambiguous grammar.\nConflict between \(firstAction) and \(secondAction)"
        case .emptyRuleDefined:
            return "Rules should have at least one right component. Use `Word(.none)` for empty rules."
        }
    }
}
