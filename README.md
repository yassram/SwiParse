<p align="center">
<img src="SwiParse.png" width="45%" alt=“SwiParse”/>
<br>
<img src="https://img.shields.io/badge/Swift-5.2-orange.svg"/>
<img src="https://img.shields.io/badge/swiftpm-compatible-brightgreen.svg"/>
<img src="https://img.shields.io/badge/platforms-iOS%20|%20macOS%20|%20Linux-brightgreen.svg"/>
<a href="https://github.com/yassram/SwiParse/actions">
<img src="https://github.com/yassram/SwiParse/workflows/TestSuite/badge.svg"/>
</a>
<a href="https://twitter.com/ramsserio">
<img src="https://img.shields.io/badge/twitter-@ramsserio-blue.svg"/>
</a>
<br>
<strong>A general-purpose parser generator library in Swift with ambiguity detection and conflicts resolution.</strong>
</p>

- [Introduction](#introduction)
- [Installation](#installation)
- [Usage](#usage)
    - [Calculator example](#calculator-example)
    - [Calculator example (ambiguous grammar)](#calculator-example-ambiguous-grammar)
        - [Associativity](#associativity)
        - [Precedence](#precedence)
- [Documentation](#documentation)
- [Features](#features)
- [Contributing](#contributing)
- [Author](#author)
- [License](#license)


## Introduction
In computer science, a parser is a program that reads a sequence of tokens (obtained from a lexer) and recognizes its semantic structure in the form of an abstract syntax tree (AST or parse tree) using the rules of a formal grammar.

**SwiParse** is a general-purpose parser generator which means that you can use it to build LR(1) parsers from any context-free grammar (in few lines of code). **SwiParse** also detects grammar ambiguity and provides mechanisms to define the rules' associativity and precedence.

***SwiParse** is fully compatible with SwiLex ([learn more](https://github.com/yassram/SwiLex))*

## Installation
**SwiParse** is distributed as a Swift Package using [SPM](https://swift.org/package-manager/).

To install `SwiParse`, add the following line to the `dependencies` list in your `Package.swift`:

```swift
.package(url: "https://github.com/yassram/SwiParse.git", .upToNextMinor(from: "1.0.0")),
```

*`SwiParse` will support other dependency managers soon.*

## Usage

Import `SwiLex` to define terminal tokens needed by the `SwiLex` lexer. :

```swift
import SwiLex
```

Import `SwiParse` to define a parser and its grammar:

```swift
import SwiParse
```

### Calculator example

In this example we will create a parser for the following grammar to build a simple calculator :

```
<expr> →   <expr> + <term> 
         | <expr> - <term> 
         | <term>

<term> →   <term> * <factor> 
         | <term> / <factor> 
         | <factor>

<fact> →   ( <expr> ) 
         | number
```

Define a `SwiLaxable` enum to list the terminal tokens of the grammar with their corresponding regular expressions:

```Swift 
enum Terminal: String, SwiLexable {
    static var separators: Set<Character> = [" "]

    case number = "[0-9]+"
    case plus = #"\+"#
    case minus = #"-"#
    case times = #"\*"#
    case divide = #"/"#

    case lParenthesis = #"\("#
    case rParenthesis = #"\)"#

    case eof
    case none   // empty token
}
```

Define a `SwiParsable` enum to list the non-terminal tokens used in the grammar:

```Swift 
enum NonTerminal: SwiParsable {
    case expr
    case fact
    case term

    case start  // starting token
}
```

Define the reduction actions for each rule of the grammar :

```Swift
func sum(a: Int, _: Substring, b: Int) -> Int { a + b }
func minus(a: Int, _: Substring, b: Int) -> Int { a - b }

func times(a: Int, _: Substring, b: Int) -> Int { a * b }
func divide(a: Int, _: Substring, b: Int) -> Int { a / b }

func parenthesis(_: Substring, a: Int, _: Substring) -> Int { a }
func toInt(s: Substring) -> Int { Int(s) ?? 0 }

func keepValue(a: Int) -> Int { a }
```

##### Important: 
In a grammar, each rule leads to the reduction of one or more terminal / non-terminal tokens (the right part of the rule) into a non-terminal token (the left part of the rule) by applying a reduction action.

The reduction action of a rule in `SwiParse` takes the value of each token being reduced by the rule as argument (the right part of the rule) and returns the new value of the reduced non-terminal token (the left part of the rule).

Terminal tokens' values are passed as Substrings (directly read by the `SwiLex` lexer) while non-terminal ones are the output of the rule that produced them (a non-terminal token is necessarily the result of a reduction rule thus its value is the output of the rule's reduction action).


Next, define a parser with the grammar by providing its rules and their reduction actions:

```Swift
let parser = try SwiParse<Terminal, NonTerminal>(rules: [
    .start => [Word(.expr)], // accepting rule

    .expr => [Word(.expr), Word(.plus), Word(.term)] >>>> sum,
    .expr => [Word(.expr), Word(.minus), Word(.term)] >>>> minus,
    .expr => [Word(.term)] >>>> keepValue,

    .term => [Word(.term), Word(.times), Word(.fact)] >>>> times,
    .term => [Word(.term), Word(.divide), Word(.fact)] >>>> divide,
    .term => [Word(.fact)] >>>> keepValue,

    .fact => [Word(.lParenthesis), Word(.expr), Word(.rParenthesis)] >>>> parenthesis,
    .fact => [Word(.number)] >>>> toInt,
])
```

> Note that each grammar should have a single starting rule that will be used as 


Finally, parse an input string using the defined parser:

```Swift
let result = try parser.parse(input: "(1 + 2) * 3")
// 9
```

### Calculator example (ambiguous grammar):

In the last example, the grammar used to define the calculator had no ambiguities. In this second example the goal is to showcase how to use the rules' precedence and operator associativity to resolve Shift/Reduce conflicts.
Let's consider the following (ambiguous) grammar:

```
<expr> →   <expr> + <expr>      // rule 0
         | <expr> - <expr>      // rule 1
         | <expr> * <expr>      // rule 2
         | <expr> / <expr>      // rule 3
         | ( <expr> )           // rule 4
         | number               // rule 5
```

#### Associativity 

If we consider the `rule 0`,  when the token `+` is read as lookahead token, and the content of the stack is `<expr> + <expr>` the parser has two options :

1. **Reduce**: the content of the stack is reduced following the `rule 0` into `<expr>` before shifting the new tokens. 
2. **Shift**: the parser shifts the next tokens before reducing them following the `rule 0` (last in first out).

This situation, where either a shift or a reduction would be valid, is called a `shift / reduce conflict`.

In the last example, choosing to `reduce` is equivalent to give priority to a `left associativity` for the `+` token while a `shift` is giving priority to a `right associativity`.

if we consider the following input string `1 + 2 + 3` (`e1`):

- With a `reduce` (`left associativity`) the result will be computed as the following:

`1`  => `1 +` => `1 + 2`  =>  `3`  => `3 +` => `3 + 3` => `6`

- With a `shift` (`right associativity`) the result will be computed as the following:

`1`  => `1 +` => `1 + 2` => `1 + 2 +` => `1 + 2 + 3` => `1 + 5` => `6`

**In other words:**

A`reduce` will consider the expression `e1` as `(1 + 2) + 3` while a `shift` will consider it as `1 + (2 + 3)`

#### Precedence

In this example the grammar has another `kind` of ambiguity. No precedence is defined between the different rules. 

If we consider the rules `rule 0` and `rule 2`, for example, when the token `*` is read as lookahead token, and the content of the stack is `<expr> + <expr>` the parser has two options :

1. **Reduce**: the content of the stack is reduced following the `rule 0` before shifting the new tokens and reducing following the `rule 2`. 
2. **Shift**: the parser shifts the next tokens, reduces following the `rule 2`  before reducing the result following the `rule 0`.

Again it's a `shift / reduce conflict`.

In the last example, choosing to `reduce` is equivalent to favoring the `+` token over the  `*` one, while a `shift` favors a `*` over `+` (`operators' precedence`).

if we consider the following input string `1 + 2 * 3` (`e1`):

- With a `reduce` (`+ < *`) the result will be computed as the following:

`1`  => `1 +` => `1 + 2`  =>  `3`  => `3 *` => `3 * 3` => `9`

- With a `shift` (`+ > *`) the result will be computed as the following:

`1`  => `1 +` => `1 + 2` => `1 + 2 *` => `1 + 2 * 3` => `1 + 6` => `7`

**In other words:**

A `reduce` will consider the expression `e1` as `(1 + 2) * 3` while a `shift` will consider it as `1 + (2 * 3)`

#### Resolving shift / reduce conflicts with SwiParse

Like before, define the terminal and non-terminal tokens of the grammar:

```Swift 
enum Terminal: String, SwiLexable {
    static var separators: Set<Character> = [" "]

    case number = "[0-9]+"
    case plus = #"\+"#
    case minus = #"-"#
    case times = #"\*"#
    case divide = #"/"#

    case lParenthesis = #"\("#
    case rParenthesis = #"\)"#

    case eof
    case none   // empty token
}

enum NonTerminal: SwiParsable {
    case expr

    case start  // starting token
}
```

Define the reduction actions for each rule of the grammar :

```Swift
func sum(a: Int, _: Substring, b: Int) -> Int { a + b }
func minus(a: Int, _: Substring, b: Int) -> Int { a - b }

func times(a: Int, _: Substring, b: Int) -> Int { a * b }
func divide(a: Int, _: Substring, b: Int) -> Int { a / b }

func parenthesis(_: Substring, a: Int, _: Substring) -> Int { a }
func toInt(s: Substring) -> Int { Int(s) ?? 0 }
```

Next, define a parser with the grammar by providing its rules and their reduction actions:

```Swift
let parser = try SwiParse<Terminal, NonTerminal>(rules: [
    .start => [Word(.expr)], // accepting rule

    .expr => [Word(.expr), Word(.plus), Word(.expr)] >>>> sum,
    .expr => [Word(.expr), Word(.minus), Word(.expr)] >>>> minus,
    .expr => [Word(.expr), Word(.times), Word(.expr)] >>>> times,
    .expr => [Word(.expr), Word(.divide), Word(.expr)] >>>> divide,
    .expr => [Word(.lParenthesis), Word(.expr), Word(.rParenthesis)] >>>> parenthesis,
    .expr => [Word(.number)] >>>> toInt,
])
```

In order to specify the `associativity` and the `precedence` of the grammar's *operators*, the parser's definition takes as argument an optional list: `priorities`.

```Swift
let parser = try SwiParse<Terminal, NonTerminal>(rules: [
    // grammar rules
], priorities [
    // priorities (associativity, precedence)
])
```

- A priority is either `.left` or `.right` to define the `associativity`.
- The index of the priority in the priority list defines the `precedence` (from low to high).

In the following example: `[.left(.tok1), .right(.tok2)]`

- `.tok1` is `left associative` and `.tok2` is `right associative`.
- `.tok2` has higher precedence than `.tok1`.

Let's specify the priority list for the example grammar to resolve the `shift / reduce` conflicts.

```Swift
let parser = try SwiParse<Terminal, NonTerminal>(rules: [
    // grammar rules
], priorities [
    .left(.plus),
    .left(.minus),
    .left(.times),
    .left(.divide),
])
```

Finally parse an input string using the defined parser:

```Swift
let result = try parser.parse(input: "1 + 2 * 3")
// 7
```

## Documentation
A documentation with more examples is available [here](https://github.com/yassram/SwiParse/wiki).

## Features
- [x] Tokens defined simply using a  `SwiLexable` enum (for terminals) and a `SwiParsable`  enum (for non-terminals).
- [x] Simple grammar definition with syntactic sugar (overrided operators).
- [x] Supports reduction actions for rules.
- [x] Grammar ambiguity (conflicts) detection.
- [x] Associativity and precedence mechanisms (conflicts resolution). 
- [x] Parsing errors detections.
- [x] Support conditional terminal tokens with custom modes and all the other `SwiLex` features.
- [x] Lexing Errors with line number and the issue's substring.
- [x] Fully compatible with all the `SwiLex` features.
- [ ] Better debugging tools (graphviz visualisation...).
- [ ] Better parsing errors.
- [ ] Files as input.
- [ ] Add detailed documentation with more examples.
- [ ] Support Cocoapods and Carthage.


## Contributing
This is an open source project, so feel free to contribute. How?
- Open an <a href="https://github.com/yassram/SwiParse/issues/new"> issue</a>.
- Send feedback via <a href="mailto:ramsserio@gmail.com">email</a>.
- Propose your own fixes, suggestions and open a pull request with the changes.

## Author
Yassir Ramdani

## License

```
MIT License

Copyright (c) 2020 yassir RAMDANI

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

