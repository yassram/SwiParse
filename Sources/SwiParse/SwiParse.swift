//
//  SwiParse.swift
//  SwiParse
//
//  Created by Yassir Ramdani on 29/09/2020.
//  Copyright © 2020 Yassir Ramdani. All rights reserved.
//

import SwiLex

public struct SwiParse<Terminal: SwiLexable, NonTerminal: SwiParsable> {
    // MARK: Internal types
    public typealias DefinedWord = Word<Terminal, NonTerminal>
    typealias ActionTable = [State: [DefinedWord: Action]]
    typealias FirstTable = [DefinedWord: Set<Terminal>]

    // MARK: Internal properties
    private(set) var rules: [Rule]!
    private(set) var priorities: [Associative]
    private(set) var parserTable: ActionTable!
    private(set) var firstTable: FirstTable!
    private var initialState: State!
    let verbose: Bool

    // MARK: Public interface

    /// Parser definition.
    ///
    /// Defines a parser for a given set of terminal and non terminal tokens, a set of rules (grammar) and tokens priorities.
    ///
    /// Rules should should include a single starting point with `.start` as left side of the rule.
    ///
    /// - Parameters:
    ///   - rules: grammar rules.
    ///   - priorities: associativity and precedence if any.
    ///   - verbose: shows debugging logs.
    /// - Throws: Parser construction errors if any.
    ///
    /// - note: The definition of the parser is costly since it builds the parsing automaton and the parsing table.
    ///
    /// For better performances try to define the parser as early as possible and use the same parser as much as possible.
    public init(rules: [Rule], priorities: [Associative] = [], verbose: Bool = false) throws {
        self.verbose = verbose
        self.priorities = priorities
        self.rules = try checkRules(rules: rules)
        self.firstTable = buildFirstTable()
        (initialState, parserTable) = try buildRules()
    }

    /// Parser's grammar redefinition.
    ///
    /// Redefines the parser's grammar with the new given rules and priorities.
    ///
    /// - Parameters:
    ///   - rules: grammar rules.
    ///   - priorities: associativity and precedence if any.
    /// - Throws: Parser construction errors if any.
    ///
    /// - note: The redefinition of the parser's grammar is costly since it builds the parsing automaton and the parsing table again.
    ///
    /// For better performances try to define the parser as early as possible and use the same parser as much as possible.
        public mutating func set(rules: [Rule], priorities: [Associative]) throws {
        self.priorities = priorities
        self.rules = try checkRules(rules: rules)
        self.firstTable = buildFirstTable()
        (initialState, parserTable) = try buildRules()
    }


    /// The parsing function.
    ///
    /// Parses an input string using a **SwiLexable** enum that defines the available **terminal** tokens and their regular expressions,
    ///  **SwiParsable**  enum that defines the available **non terminal** tokens and a grammar (list of rules and priorities).
    ///
    /// - Parameter input: the input String to be parsed.
    /// - Throws: Lexing and parsing errors if any.
    /// - Returns: The result of parsing actions defined in rules.
    ///
    /// # Example
    ///
    /// ```
    ///  enum NonTerminal: SwiParsable {
    ///     case exp
    ///     case start
    ///  }
    ///
    /// enum Terminal: String, SwiLexable {
    ///     static var separators: Set<Character> = [" "]
    ///
    ///     case n = "[0-9]+"
    ///     case plus = #"\+"#
    ///
    ///     case eof
    ///     case none
    /// }
    ///
    /// func toInt(s: Substring) -> Int { Int(s) ?? 0 }
    /// func sum(a: Int, op _: Substring, b: Int) -> Int { a + b }
    ///
    ///
    /// let parser = try SwiParse<Terminal, NonTerminal>(rules: [
    ///        .start => [Word(.exp)],
    ///        .exp => [Word(.exp), Word(.plus), Word(.exp)] >>>> sum,
    ///        .exp => [Word(.n)] >>>> toInt,
    ///
    ///    ], priorities: [
    ///        .left(.plus),
    ///    ], verbose: false)
    /// }
    ///
    /// let result = try parser.parse(input: " 40 + 2 ")
    /// // 42
    ///
    /// ```
    public func parse(input: String) throws -> Any? {
        var lexer = SwiLex<Terminal>()
        let inputStr = try lexer.lex(input: input)

        let tokenStack = Stack(contentsOf: inputStr)
        let parsingStack = Stack<DefinedWord>()
        let dataStack = Stack<Any>()
        let stateStack = Stack<State>(with: initialState)

        while !tokenStack.isEmpty,
            let lookAhead = tokenStack.look {
            let actions = parserTable[stateStack.look!]!
            guard let action = actions[Word(lookAhead.type)] else {
                if verbose { print(parsingStack, "\n", dataStack, "\n", stateStack.data.map { $0.id }, "\n", actions, "\n", tokenStack, "\n") }
                throw ParseError.parsingError(Array(actions.keys), lookAhead)
            }
            if verbose { print(parsingStack, "\n", dataStack, "\n", stateStack.data.map { $0.id }, "\n", actions, "\n", tokenStack, "\n") }
            actionExec(action: action, tokenStack: tokenStack, parsingStack: parsingStack,
                       dataStack: dataStack, stateStack: stateStack)
        }

        return dataStack.pop()
    }
}
