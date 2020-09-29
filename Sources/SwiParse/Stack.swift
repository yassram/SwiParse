//
//  Stack.swift
//  SwiParse
//
//  Created by Yassir Ramdani on 09/11/2020.
//  Copyright © 2020 Yassir Ramdani. All rights reserved.
//

import Foundation

extension SwiParse {
    final class Stack<Item> {
        var data: [Item] = []
        var isEmpty: Bool { data.isEmpty }
        var look: Item? { data.last }

        init() {}

        init(contentsOf data: [Item]) {
            self.data = data.reversed()
        }

        init(with item: Item) {
            push(item: item)
        }
    }
}

extension SwiParse.Stack {
    func push(item: Item) { data.append(item) }

    @discardableResult
    func pop() -> Item? { data.popLast() }

    @discardableResult
    func pop(_ n: Int) -> [Item]? {
        if data.count < n { return nil }
        var result = [Item]()
        for _ in 0 ..< n {
            result.insert(pop()!, at: 0)
        }
        return result
    }
}

// MARK: Description

extension SwiParse.Stack: CustomStringConvertible {
    var description: String {
        "\(data.map{$0})"
    }
}
