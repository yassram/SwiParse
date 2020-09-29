@testable import SwiParse
@testable import SwiLex
import XCTest

final class ArithmeticParserTests: XCTestCase {
    enum NonTerminal: SwiParsable {
        case exp
        case start
    }

    enum Terminal: String, SwiLexable {
        static var separators: Set<Character> = [" "]

        case n = "[0-9]+"
        case plus = #"\+"#
        case minus = #"-"#
        case times = #"\*"#
        case divide = #"/"#
        case lParenthesis = #"\("#
        case rParenthesis = #"\)"#

        case eof
        case none
    }

    func toInt(s: Substring) -> Int { Int(s) ?? 0 }
    func sum(a: Int, _: Substring, b: Int) -> Int { a + b }
    func minus(a: Int, _: Substring, b: Int) -> Int { a - b }
    func times(a: Int, _: Substring, b: Int) -> Int { a * b }
    func divide(a: Int, _: Substring, b: Int) -> Int { a / b }
    func parenthesis(_: Substring, a: Int, _: Substring) -> Int { a }

    func initParser() throws -> SwiParse<Terminal, NonTerminal> {
        try SwiParse<Terminal, NonTerminal>(rules: [
            .start => [Word(.exp)],
            .exp => [Word(.none)] >>>> {0}, // accept empty expression as 0
            .exp => [Word(.exp), Word(.plus), Word(.exp)] >>>> sum,
            .exp => [Word(.exp), Word(.minus), Word(.exp)] >>>> minus,
            .exp => [Word(.exp), Word(.times), Word(.exp)] >>>> times,
            .exp => [Word(.exp), Word(.divide), Word(.exp)] >>>> divide,
            .exp => [Word(.n)] >>>> toInt,
            .exp => [Word(.lParenthesis), Word(.exp), Word(.rParenthesis)] >>>> parenthesis,
        ], priorities: [
            .left(.plus),
            .left(.minus),
            .left(.times),
            .left(.divide),
        ])
    }

    func testOutput(for input: String, expected: Int, using parser: SwiParse<Terminal, NonTerminal>) throws {
        let output = try parser.parse(input: input) as? Int
        XCTAssertNotNil(output)
        let castedOut = output!
        XCTAssertEqual(castedOut, expected)
    }

    func testInit() throws {
        let parser = try initParser()
        XCTAssertNotNil(parser)
    }

    func testEmpty() throws {
        let parser = try initParser()
        try testOutput(for: "", expected: 0, using: parser)
    }

    func testSimple() throws {
        let parser = try initParser()
        XCTAssertNotNil(parser)
        try testOutput(for: "1", expected: 1, using: parser)
    }

    func testSimpleSum() throws {
        let parser = try initParser()
        XCTAssertNotNil(parser)
        try testOutput(for: "1+1", expected: 2, using: parser)
        try testOutput(for: "1+ 1", expected: 2, using: parser)
        try testOutput(for: "1 +1", expected: 2, using: parser)
        try testOutput(for: "1 + 1", expected: 2, using: parser)
        try testOutput(for: "        1 + 1", expected: 2, using: parser)
        try testOutput(for: "1 + 1        ", expected: 2, using: parser)
        try testOutput(for: "1 +         1", expected: 2, using: parser)
        try testOutput(for: "1         + 1", expected: 2, using: parser)
        try testOutput(for: "1     +     1", expected: 2, using: parser)
        try testOutput(for: "      1     +     1     ", expected: 2, using: parser)
    }

    func testSimpleMultiplication() throws {
        let parser = try initParser()
        XCTAssertNotNil(parser)
        try testOutput(for: "2*10", expected: 20, using: parser)
        try testOutput(for: "2* 10", expected: 20, using: parser)
        try testOutput(for: "2 *10", expected: 20, using: parser)
        try testOutput(for: "2 * 10", expected: 20, using: parser)
        try testOutput(for: "        2 * 10", expected: 20, using: parser)
        try testOutput(for: "2 * 10        ", expected: 20, using: parser)
        try testOutput(for: "2 *         10", expected: 20, using: parser)
        try testOutput(for: "2         * 10", expected: 20, using: parser)
        try testOutput(for: "2     *     10", expected: 20, using: parser)
        try testOutput(for: "      2     *     10     ", expected: 20, using: parser)
    }

    func testSimpleSumMultiplication() throws {
        let parser = try initParser()
        XCTAssertNotNil(parser)
        try testOutput(for: "42 + 2*10", expected: 62, using: parser)
        try testOutput(for: "42+2* 10", expected: 62, using: parser)
        try testOutput(for: "42+2 *10", expected: 62, using: parser)
        try testOutput(for: "42+2 * 10", expected: 62, using: parser)
        try testOutput(for: " 42+       2 * 10", expected: 62, using: parser)
        try testOutput(for: "2 * 10 + 42        ", expected: 62, using: parser)
        try testOutput(for: "2 *         10+42", expected: 62, using: parser)
        try testOutput(for: "2         * 10 + 42", expected: 62, using: parser)
        try testOutput(for: "2     *     10+ 42", expected: 62, using: parser)
        try testOutput(for: "      2     *     10 +42     ", expected: 62, using: parser)
    }

    func testSimpleMinusMultiplication() throws {
        let parser = try initParser()
        XCTAssertNotNil(parser)
        try testOutput(for: "42 - 2*10", expected: 22, using: parser)
        try testOutput(for: "42-2* 10", expected: 22, using: parser)
        try testOutput(for: "42-2 *10", expected: 22, using: parser)
        try testOutput(for: "42-2 * 10", expected: 22, using: parser)
        try testOutput(for: " 42-       2 * 10", expected: 22, using: parser)
        try testOutput(for: "2 * 10 - 42        ", expected: -22, using: parser)
        try testOutput(for: "2 *         10-42", expected: -22, using: parser)
        try testOutput(for: "2         * 10 - 42", expected: -22, using: parser)
        try testOutput(for: "2     *     10- 42", expected: -22, using: parser)
        try testOutput(for: "      2     *     10 -42     ", expected: -22, using: parser)
    }

    func testComplexExpression() throws {
        let parser = try initParser()
        XCTAssertNotNil(parser)
        try testOutput(for: "((((((((((()))))))))))", expected: 0, using: parser)
        try testOutput(for: "((((((((1))))))))", expected: 1, using: parser)
        try testOutput(for: "2*(3+3)", expected: 12, using: parser)
        try testOutput(for: "2*(3+3)*3", expected: 36, using: parser)
        try testOutput(for: "((((((((((((((((2*(3+3)*3))))))))))))))))", expected: 36, using: parser)
        try testOutput(for: "((((((((((((((((*(+)*))))))))))))))))", expected: 0, using: parser)
    }

    static var allTests = [
        ("testInit", testInit),
        ("testParse", testEmpty),
        ("testParse", testSimple),
        ("testSimpleSum", testSimpleSum),
        ("testSimpleMultiplication", testSimpleMultiplication),
        ("testSimpleSumMultiplication", testSimpleSumMultiplication),
        ("testComplexExpression", testComplexExpression),
    ]
}
