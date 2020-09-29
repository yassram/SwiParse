//
//  LRParser.swift
//  SwiParse
//
//  Created by Yassir Ramdani on 08/10/2020.
//  Copyright © 2020 Yassir Ramdani. All rights reserved.
//

import Foundation
import SwiLex

extension SwiParse {
    /// Prints the the parser's table for debugging.
    ///
    /// Activated by setting `verbose` to true.
    func parserTableLogs(parserTable: ActionTable) {
        if !verbose { return }
        parserTable
            .sorted { $0.key.id < $1.key.id }
            .forEach { (key: State, value: [Word: Action]) in
                print(key.id, terminator: "  ")
                value.forEach { (key: Word, value: Action) in
                    print("\(key)->\(value)", terminator: "  ")
                }
                print("")
            }
    }

    /// Prints the the parser's automaton for debugging.
    ///
    /// Activated by setting `verbose` to true.
    func parserStatesLogs(statesList: [State]) {
        if !verbose { return }
        statesList.forEach { print($0) }
    }

    /// Checks if the grammar satisfies all the **SwiParse** requirements.
    func checkRules(rules: [Rule]) throws -> [Rule] {
        if !rules.allSatisfy({ $0.right.count > 0 }) { throw ParseError.emptyRuleDefined }
        return rules
    }

    /// Builds parser's table from the grammar's rules.
    func buildRules() throws -> (State, ActionTable) {
        let startingRules = rules.filter { $0.left == .start }
        if startingRules.count > 1 { throw ParseError.multipleStartingRulesDefined }
        guard let startingRule = startingRules.first else { throw ParseError.noStartingRuleDefined }

        let initialState = State(id: 0, items: closure(items: [Item(rule: startingRule, index: 0, follow: Terminal.eof)]))
        let statesList = computeStates(initState: initialState)
        parserStatesLogs(statesList: statesList)

        let parserTable = try table(from: statesList)
        parserTableLogs(parserTable: parserTable)

        return (initialState, parserTable)
    }

    /// Builds the first table.
    func buildFirstTable() -> FirstTable {
        var firstList = [DefinedWord: Set<Terminal>]()
        // init first list for every token.
        firstList[Word(.none)] = [.none]
        for word in DefinedWord.all {
            switch word {
            case let .terminal(terminal):
                firstList[word] = [terminal]
            case .nonTerminal:
                firstList[word] = []
            }
        }
        // fill the first lists using rules.
        var changed = true
        while changed {
            changed = false
            for rule in rules {
                let productionResult = DefinedWord(rule.left)
                for word in rule.right {
                    if firstList[word]!.contains(.none) { break }
                    let before = firstList[productionResult]!
                    firstList[productionResult]!.formUnion(firstList[word]!.subtracting([Terminal.none]))
                    if before != firstList[productionResult]! {changed = true}
                }
                if let lastWord = rule.right.last,
                   firstList[lastWord]!.contains(.none) {
                    let before = firstList[productionResult]!
                    firstList[productionResult]!.formUnion([Terminal.none])
                    if before != firstList[productionResult]! {changed = true}
                }
            }
        }
        return firstList
    }

    /// Returns the first list for a given word.
    func getFirst(of word: DefinedWord) -> Set<Terminal> {
        firstTable[word]!
    }

    /// Builds a set of equivalent items from a given item.
    func closure(items: Set<Item>) -> Set<Item> {
        var itemsFinal = items
        var changed = true
        while changed {
            changed = false
            for item in itemsFinal {
                if item.next() == Word(.none) {
                    let nexItem = Item(rule: item.rule, index: item.index + 1, follow: item.follow)
                    if itemsFinal.insert(nexItem).inserted { changed = true }
                }
                //  [A → β•Bδ, a]
                guard let next = item.next(),
                    case let Word.nonTerminal(B) = next else { continue }
                for rule in rules {
                    // [B → τ, b]
                    if rule.left == B {
                        var firstOfSigmaA = Set<Terminal>()
                        if let sigma = item.next(1) {
                            firstOfSigmaA = getFirst(of: sigma)
                            if firstOfSigmaA.contains(.none) {
                                let firstOfSigma = getFirst(of: Word(item.follow))
                                firstOfSigmaA.formUnion(firstOfSigma)
                            }
                        } else {
                            firstOfSigmaA = getFirst(of: Word(item.follow))
                        }
                        for b in firstOfSigmaA {
                            // [B → •τ, b]
                            let newItem = Item(rule: rule, index: 0, follow: b)
                            if itemsFinal.insert(newItem).inserted { changed = true }
                        }
                    }
                }
            }
        }
        return itemsFinal
    }

    /// Returns all possible items from `state` when `word` is read.
    func go(from state: State, using word: DefinedWord) -> Set<Item> {
        var nextStateItems = Set<Item>()
        for item in state.items {
            if item.next() == word {
                let nexItem = Item(rule: item.rule, index: item.index + 1, follow: item.follow)
                nextStateItems.insert(nexItem)
            }
        }
        return closure(items: nextStateItems)
    }

    /// Computs all the automaton nodes and transition from a given starting state.
    func computeStates(initState: State) -> [State] {
        var result = [initState]
        var changed = true
        var stateId = 1
        while changed {
            changed = false
            for i in 0 ..< result.count {
                let currentState = result[i]
                for word in DefinedWord.all {
                    let items = go(from: currentState, using: word)
                    if items.isEmpty { continue }
                    let newState = State(id: stateId, items: items)
                    // add a goTo transition from curentState using word
                    if let found = result.first(where: { $0.items == items }) {
                        currentState.goTo[word] = found
                    } else {
                        currentState.goTo[word] = newState
                    }
                    // add the new state to the list
                    if !result.contains(newState) {
                        result.append(newState)
                        changed = true
                        stateId += 1
                    }
                }
            }
        }
        return result
    }

    /// Solves the reduce conflicts.
    func solveReduceConflict(actionTable: inout ActionTable, state: State, word: DefinedWord, action: Action) throws {
        // We already have a reduce action for word
        if case Action.accept = action {
            // always accept if possible!
            actionTable[state]![word] = action
            return
        }
        if case let Action.reduce(rule) = actionTable[state]![word]! {
            // avoid reducing .none
            if rule.right.contains(DefinedWord(.none)) {
                actionTable[state]![word] = action
            }
            return
        }

        print(state)
        throw ParseError.AmbiguousGrammar(actionTable[state]![word]!.description, action.description)
    }

    /// Solves the shift conflicts.
    func solveShiftConflict(actionTable: inout ActionTable, state: State, word: DefinedWord, action: Action) throws {
        // We already have a shift action for word
        guard case let Action.reduce(reduceRule) = action else {
            if case Action.accept = action {
                // always accept if possible !
                actionTable[state]![word] = action
                return
            }
            print(state)
            throw ParseError.AmbiguousGrammar(actionTable[state]![word]!.description, action.description)
        }

        // Shift / Reduce conflict
        if verbose { print("Shift/Reduce conflict:", reduceRule, "shift[\(word)]", terminator:"") }

        // associativity
        for priority in priorities {
            switch priority {
            // Left associative => Reduce
            case let .left(terminal):
                if Word(terminal) == word {
                    if reduceRule.lastTerminal == word {
                        // replace the current action with the reduce
                        if verbose { print(" resolved by REDUCE") }
                        actionTable[state]![word] = action
                        return
                    }
                }
            // Right associative => Shift
            case let .right(terminal):
                if Word(terminal) == word {
                    if reduceRule.lastTerminal == word {
                        if verbose { print(" resolved by SHIFT") }
                        // keep the current action (shift)
                        return
                    }
                }
            }
        }

        // precedence
        let precedence = priorities.filter { Word($0.token) == word || Word($0.token) == reduceRule.lastTerminal }.map { $0.token }
        // if no precendence is defined then Shift/Reduce Conflict
        guard precedence.count == 2 else { throw ParseError.shiftReduceConflict(word, action.description) }
        if Word(precedence[1]) == reduceRule.lastTerminal {
            // reduce has higher precedence (precedence is declared from low to high)
            // replace the current action with the reduce
            actionTable[state]![word] = action
            if verbose { print(" resolved by REDUCE") }
            return
        }
        if verbose { print(" resolved by SHIFT") }
        // keep the current action (shift)
        return
    }

    /// Adds an action to the parsing table.
    func addTo(actionTable: inout ActionTable, state: State, word: DefinedWord, action: Action) throws {
        guard let stateActionTable = actionTable[state] else {
            // new action for word
            actionTable[state] = [word: action]
            return
        }

        guard stateActionTable[word] != nil else {
            // new action for word
            actionTable[state]![word] = action
            return
        }

        switch stateActionTable[word]! {
        case .accept:
            // always accept if possible !
            return
        case .shift:
            try solveShiftConflict(actionTable: &actionTable, state: state, word: word, action: action)
        case .reduce:
            try solveReduceConflict(actionTable: &actionTable, state: state, word: word, action: action)
        case .goTo:
            throw ParseError.AmbiguousGrammar(stateActionTable[word]!.description, action.description)
        }
    }

    /// Turns the automaton into a parsing table.
    func table(from states: [State]) throws -> ActionTable {
        var actionTable = ActionTable()
        for state in states {
            for (key, val) in state.goTo {
                if case Word.terminal = key {
                    try addTo(actionTable: &actionTable, state: state, word: key, action: .shift(val))
                } else if case Word.nonTerminal = key {
                    try addTo(actionTable: &actionTable, state: state, word: key, action: .goTo(val))
                }
            }
            for item in state.items {
                if item.index == item.rule.right.count {
                    if item.rule.left == NonTerminal.start, item.follow == Terminal.eof {
                        try addTo(actionTable: &actionTable, state: state, word: .terminal(item.follow), action: .accept)
                    } else {
                        try addTo(actionTable: &actionTable, state: state, word: .terminal(item.follow), action: .reduce(item.rule))
                    }
                }
            }
        }
        return actionTable
    }

    /// Applies a reduction rule.
    func apply(rule: Rule, to parsingStack: Stack<DefinedWord>, data: Stack<Any>, stateStack: Stack<State>) {
        if rule.right.contains(DefinedWord(.none)) {
            let dataResult = rule.action([])
            data.push(item: dataResult)
            let new = DefinedWord(rule.left)
            parsingStack.push(item: new)
            return
        }
        parsingStack.pop(rule.right.count)
        stateStack.pop(rule.right.count)
        let datainput = data.pop(rule.right.count)!
        let dataResult = rule.action(datainput)
        data.push(item: dataResult)
        let new = DefinedWord(rule.left)
        parsingStack.push(item: new)
    }

    /// Applies the next parsing action..
    func actionExec(action: Action, tokenStack: Stack<Token<Terminal>>, parsingStack: Stack<DefinedWord>, dataStack: Stack<Any>, stateStack: Stack<State>) {
        switch action {
        case .accept:
            tokenStack.pop()
        case let .shift(state):
            let currentShift = tokenStack.pop()!
            parsingStack.push(item: DefinedWord(currentShift.type))
            dataStack.push(item: currentShift.value)
            stateStack.push(item: state)
        case let .reduce(rule):
            apply(rule: rule, to: parsingStack, data: dataStack, stateStack: stateStack)
            if case let .goTo(newState) = parserTable[stateStack.look!]![parsingStack.look!]! {
                stateStack.push(item: newState)
            }
        case let .goTo(state):
            stateStack.push(item: state)
        }
    }
}
