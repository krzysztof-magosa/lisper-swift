func inferNumberType(_ args: [Node]) throws -> NumberType {
    for arg in args {
        if (arg as! NumberNode).type == .float {
            return .float
        }
    }

    return .integer // default
}

enum InterpreterError: Error {
    case undefinedVariable(name: String)
    case invalidType(context: String, index: Int, got: Node.Type, expected: [Node.Type])
    case nargs(context: String, got: Int, expected: (Int, Int))
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
            throw InterpreterError.undefinedVariable(name: name)
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

func expect_nargs(_ context: String, _ args: [Node], _ expected: (Int, Int)) throws {
    let got = args.count

    if got < expected.0 || got > expected.1 {
        throw InterpreterError.nargs(context: context, got: got, expected: expected)
    }
}

func expect_nargs(_ context: String, _ args: [Node], _ expected: Int) throws {
    try expect_nargs(context, args, (expected, expected))
}

func expect_type(_ context: String, _ args: [Node], _ index: Int, _ types: [Node.Type]) throws {
    var got = type(of: args[index])
    if !types.contains(where: { $0 == got }) {
        throw InterpreterError.invalidType(context: context, index: index, got: got, expected: types)
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
        try expect_nargs("define", args, 2)
        try expect_type("define", args, 0, [SymbolNode.self])

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
                try expect_type("eval", l.elements, 0, [SymbolNode.self])
                let s = l.elements[0] as! SymbolNode

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
