//
//  State.swift
//  SwiParse
//
//  Created by Yassir Ramdani on 29/09/2020.
//  Copyright © 2020 Yassir Ramdani. All rights reserved.
//

import Foundation

extension SwiParse {
    /// A node of the **SwiParse** parser's automaton.
    final class State {
        /// The state id.
        let id: Int
        /// The state items.
        let items: Set<Item>
        /// the state possible transitions.
        var goTo: [DefinedWord: State] = [:]

        init(id: Int, items: Set<Item>) {
            self.id = id
            self.items = items
        }
    }
}

// MARK: Description

extension SwiParse.State: CustomStringConvertible {
    var description: String {
        "State \(id):\n\(items.map { "\($0)\n" }.joined())\(goTo.map { "\($0) -> \($1.id)\n" }.joined())"
    }
}

// MARK: Hashable

extension SwiParse.State: Hashable {
    static func == (lhs: SwiParse.State, rhs: SwiParse.State) -> Bool {
        lhs.items == rhs.items
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
