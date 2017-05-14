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
        return a.name == NIL_NAME && b == NIL_VALUE
    case (let b as ListNode, let a as SymbolNode):
        return a.name == NIL_NAME && b == NIL_VALUE


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

    static func +(lhs: NumberNode, rhs: NumberNode) -> NumberNode {
        return NumberNode(
          type: inferNumberType([lhs, rhs]),
          value: lhs.value + rhs.value
        )
    }

    static func -(lhs: NumberNode, rhs: NumberNode) -> NumberNode {
        return NumberNode(
          type: inferNumberType([lhs, rhs]),
          value: lhs.value - rhs.value
        )
    }

    static func /(lhs: NumberNode, rhs: NumberNode) -> NumberNode {
        return NumberNode(
          type: inferNumberType([lhs, rhs]),
          value: lhs.value / rhs.value
        )
    }

    static func *(lhs: NumberNode, rhs: NumberNode) -> NumberNode {
        return NumberNode(
          type: inferNumberType([lhs, rhs]),
          value: lhs.value * rhs.value
        )
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
            return NIL_NAME
        }
    }

    static func +(lhs: ListNode, rhs: ListNode) -> ListNode {
        return ListNode(elements: lhs.elements + rhs.elements)
    }
}
