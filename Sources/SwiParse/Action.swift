//
//  Action.swift
//  SwiParse
//
//  Created by Yassir Ramdani on 29/09/2020.
//  Copyright © 2020 Yassir Ramdani. All rights reserved.
//

import Foundation

extension SwiParse {
    /// Parser's possible actions.
    enum Action {
        /// Shift action of the lookahead token.
        case shift(State)
        /// Accept action.
        case accept
        /// Reduce action using a grammar rule.
        case reduce(Rule)
        /// GoTo action to move to a new parser's state.
        case goTo(State)
    }
}

extension SwiParse.Action: CustomStringConvertible {
    var description: String {
        switch self {
        case .accept:
            return "accept"
        case let .shift(state):
            return "shift[\(state.id)]"
        case let .reduce(rule):
            return "reduce[\(rule)]"
        case let .goTo(state):
            return "goto[\(state.id)]"
        }
    }
}
