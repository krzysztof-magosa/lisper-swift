enum ParseError: Error {
    case unexpectedToken(TokenType)
    case unexpectedEOF
}

let modifierMapping: [String: String] = [
  "'": "quote",
  "`": "quasiquote",
  ",": "unquote"
]

class Parser {
    let input: [Token]
    var index: Int

    init(input: [Token]) {
        self.input = input
        self.index = input.startIndex
    }

    var peek: Token? {
         return self.index < self.input.endIndex ? self.input[self.index] : nil
    }

    func consume() {
        self.index += 1
    }

    func consume(_ type: TokenType) throws {
        guard let current = peek else {
            throw ParseError.unexpectedEOF
        }

        guard current.type == type else {
            throw ParseError.unexpectedToken(type)
        }

        consume()
    }

    func parseAny() throws -> Node? {
        while let token = peek {
            switch token.type {
            case .integer:
                consume()
                return NumberNode(type: .integer, value: Double(token.payload)!)
            case .float:
                consume()
                return NumberNode(type: .float, value: Double(token.payload)!)
            case .string():
                consume()
                return StringNode(value: token.payload)
            case .symbol:
                consume()
                return SymbolNode(name: token.payload)
            case .modifier:
                consume()
                guard peek != nil else {
                    throw ParseError.unexpectedEOF
                }

                return ListNode(
                  elements: [
                    SymbolNode(name: modifierMapping[token.payload]!),
                    try parseAny()!
                  ]
                )
            case .lparen:
                consume()
                var elements = [Node]()
                while let t = peek, t.type != TokenType.rparen {
                    elements.append(try parseAny()!)
                }
                try consume(.rparen)
                return ListNode(elements: elements)
            default:
                throw ParseError.unexpectedToken(token.type)
            }
        }

        return nil
    }

    func parse() throws -> [Node] {
        index = 0

        var nodes = [Node]()
        while index < input.count {
            nodes.append(try parseAny()!)
        }

        return nodes
    }
}
