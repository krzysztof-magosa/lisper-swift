protocol Node: CustomStringConvertible {
    static var lispType: String { get }
}

func ==(lhs: Node, rhs: Node) -> Bool {
    switch (lhs, rhs) {
    case (let a as NumberNode, let b as NumberNode):
        return a.value == b.value
    case (let a as StringNode, let b as StringNode):
        return a.value == b.value
    case (let a as SymbolNode, let b as SymbolNode):
        return a.name == b.name
    case (let a as ListNode, let b as ListNode):
        return a.elements == b.elements

    // nil == () and vice versa
    case (let a as SymbolNode, let b as ListNode):
        return a.name == NIL_NAME && b.elements.count == 0
    case (let b as ListNode, let a as SymbolNode):
        return a.name == NIL_NAME && b.elements.count == 0


    default:
        return false
    }
}

func !=(lhs: Node, rhs: Node) -> Bool {
    return !(lhs == rhs)
}


func ==(lhs: [Node], rhs: [Node]) -> Bool {
    guard lhs.count == rhs.count else {
        return false
    }

    for i in 0..<lhs.count {
        if lhs[i] != rhs[i] {
            return false
        }
    }

    return true
}


enum NumberType {
    case integer
    case float
}

struct NumberNode: Node {
    static let lispType = "NUMBER"
    let type: NumberType
    let value: Double

    var description: String {
        switch(type) {
        case .integer:
            return "\(Int(value))"
        case .float:
            return "\(value)"
        }
    }

}

struct StringNode: Node {
    static let lispType = "STRING"
    let value: String

    var description: String {
        return "\"\(value)\""
    }
}

struct SymbolNode: Node {
    static let lispType = "SYMBOL"
    let name: String

    var description: String {
        return name
    }
}

struct ListNode: Node {
    static let lispType = "LIST"
    let elements: [Node]

    var description: String {
        if elements.count > 0 {
            let inner = elements.map({ "\($0)" }).joined(separator: " ")
            return "(\(inner))"
        } else {
            return "nil"
        }
    }
}

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
