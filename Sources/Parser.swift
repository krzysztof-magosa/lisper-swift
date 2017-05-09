indirect enum Node {
    case list([Node?])

    case symbol(String)
    case string(String)
    case integer(Int)
    case float(Double)
}

enum ParseError: Error {
    case unexpectedToken(Token)
    case unexpectedEOF
}

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

    func consume(_ token: Token) throws {
        guard let current = peek else {
            throw ParseError.unexpectedEOF
        }

        guard current.id == token.id else {
            throw ParseError.unexpectedToken(token)
        }

        consume()
    }

    func parseAll() throws -> Node? {
        while let token = peek {
            switch token {
            case .symbol(let v):
                consume()
                return .symbol(v)
            case .string(let v):
                consume()
                return .string(v)
            case .integer(let v):
                consume()
                return .integer(v)
            case .float(let v):
                consume()
                return .float(v)

            case .quote():
                consume()
                guard peek != nil else {
                    throw ParseError.unexpectedEOF
                }
                return .list([.symbol("quote"), try parseAll()])

            case .tick():
                consume()
                guard peek != nil else {
                    throw ParseError.unexpectedEOF
                }
                return .list([.symbol("quasiquote"), try parseAll()])

            case .comma():
                consume()
                guard peek != nil else {
                    throw ParseError.unexpectedEOF
                }
                return .list([.symbol("unquote"), try parseAll()])

            case .lparen:
                consume()
                var elements = [Node]()
                while let t = peek, t.id != Token.rparen.id {
                    elements.append(try parseAll()!)
                }
                try consume(.rparen)
                return .list(elements)
            default:
                throw ParseError.unexpectedToken(token)
            }
        }

        return nil
    }

    func parse() {
        let x = try! parseAll()
        print(x!)
    }
}
