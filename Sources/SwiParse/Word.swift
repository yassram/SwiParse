//
//  Word.swift
//  SwiParse
//
//  Created by Yassir Ramdani on 29/09/2020.
//  Copyright © 2020 Yassir Ramdani. All rights reserved.
//

import SwiLex

/// A wrapper for terminal and non terminal tokens.
public enum Word<Terminal: SwiLexable, NonTerminal: SwiParsable>: Hashable {
    case terminal(Terminal)
    case nonTerminal(NonTerminal)

    public init(_ terminalToken: Terminal) {
        self = .terminal(terminalToken)
    }

    public init(_ nonTerminalToken: NonTerminal) {
        self = .nonTerminal(nonTerminalToken)
    }
}

public extension Word {
    /// A list of user defined tokens (terminals and non terminals).
    static var all: [Word] {
        NonTerminal.allCases.map { Word.nonTerminal($0) } + Terminal.allCases.filter { $0 != .none }.map { Word.terminal($0) }
    }
}

// MARK: Description

extension Word: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .terminal(val):
            return "\(val)"
        case let .nonTerminal(val):
            return "\(val)"
        }
    }
}
