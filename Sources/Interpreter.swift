func onlyNumbers(_ items: [Node]) throws {
    for item in items {
        if !(item is NumberNode) {
            throw InterpreterError.notanumber
        }
    }
}

func inferNumberType(_ args: [Node]) throws -> NumberType {
    for arg in args {
        if (arg as! NumberNode).type == .float {
            return .float
        }
    }

    return .integer // default
}

enum InterpreterError: Error {
    case undefinedVariable(String)
    case notanumber
    case notasymbol
}

class Scope {
    var data: [String: Node]
    var parent: Scope?

    init(parameters: [String] = [], arguments: [String] = [], parent: Scope? = nil) {
        self.data = [:]
        // put data
        self.parent = parent
    }

    func findScope(_ name: String) throws -> Scope {
        if self.data[name] != nil {
            return self
        } else if self.parent != nil {
            return try self.parent!.findScope(name)
        } else {
            throw InterpreterError.undefinedVariable(name)
        }
    }

    func get(_ name: String) throws -> Node {
        return try findScope(name).data[name]!
    }

    func define(_ name: String, _ node: Node) {
        data[name] = node
    }

    func set(_ name: String, _ node: Node) throws {
        try self.findScope(name).data[name] = node
    }
}

class Interpreter {
    var globalScope: Scope
    var builtins: [String: ([Node], Scope) throws -> (Node)] = [:]

    func builtin_begin(_ args: [Node], _ scope: Scope) throws -> Node {
        let evaled_args = try eval_all(args, scope: scope)
        return evaled_args.last!
    }

    func builtin_define(_ args: [Node], _ scope: Scope) throws -> Node {
        let name = args[0]
        let value = try eval(args[1], scope: scope)

        scope.define((name as! SymbolNode).name, value)
        return name
    }

    func builtin_math_add(_ args: [Node], _ scope: Scope) throws -> Node {
        let evaled_args = try eval_all(args, scope: scope)
        let numbers = evaled_args.map({ ($0 as! NumberNode).value })

        // create support for integers
        return NumberNode(
          type: try inferNumberType(evaled_args),
          value: numbers.reduce(0, +)
        )
    }

    init() {
        self.globalScope = Scope()
        self.builtins["begin"]   = self.builtin_begin
        self.builtins["define"]  = self.builtin_define
        self.builtins["+"]       = self.builtin_math_add
    }

    func eval_all(_ nodes: [Node], scope: Scope) throws -> [Node] {
        return try nodes.map { try eval($0, scope: scope) }
    }

    func eval(_ node: Node, scope: Scope) throws -> Node {
        switch node {
        case let s as SymbolNode:
            return try scope.get(s.name)
        case let v as NumberNode:
            return v
        case let v as StringNode:
            return v
        case let l as ListNode:
            if l.elements.count == 0 {
                return l
            } else {
                guard let s = l.elements[0] as? SymbolNode else {
                    throw InterpreterError.notasymbol
                }

                if let builtin = builtins[s.name] {
                    return try builtin(Array(l.elements.dropFirst()), scope)
                } else {
                    return ListNode(elements: [])
                }
            }
        default:
            return ListNode(elements: [])
        }
    }

    func run(_ node: Node) throws -> Node {
        return try eval(node, scope: self.globalScope)
    }
}
