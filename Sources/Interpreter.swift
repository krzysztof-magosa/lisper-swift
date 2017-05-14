func inferNumberType(_ args: [NumberNode]) -> NumberType {
    for arg in args {
        if arg.type == .float {
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
        // @TODO put data
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
    let got = type(of: args[index])
    if !types.contains(where: { $0 == got }) {
        throw InterpreterError.invalidType(context: context, index: index, got: got, expected: types)
    }
}

class Interpreter {
    var globalScope: Scope
    var builtins: [String: ([Node], Scope) throws -> (Node)] = [:]

    func builtin_quote(_ args: [Node], _ scope: Scope) throws -> Node {
        return args[0]
    }

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
        for i in 0..<args.count {
            try expect_type("+", evaled_args, i, [NumberNode.self])
        }

        let numbers = evaled_args.map({ $0 as! NumberNode })
        return numbers.reduce(NumberNode(type: .integer, value: 0), +)
    }

    func builtin_math_sub(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("-", args, (2, Int.max))
        let evaled_args = try eval_all(args, scope: scope)
        for i in 0..<args.count {
            try expect_type("-", evaled_args, i, [NumberNode.self])
        }

        let numbers = evaled_args.map({ $0 as! NumberNode })
        return numbers.dropFirst().reduce(numbers.first!, -)
    }

    func builtin_math_div(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("/", args, (2, Int.max))
        let evaled_args = try eval_all(args, scope: scope)
        for i in 0..<args.count {
            try expect_type("/", evaled_args, i, [NumberNode.self])
        }

        let numbers = evaled_args.map({ $0 as! NumberNode })
        return numbers.dropFirst().reduce(numbers.first!, /)
    }

    func builtin_math_mul(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("*", args, (1, Int.max))
        let evaled_args = try eval_all(args, scope: scope)
        for i in 0..<args.count {
            try expect_type("*", evaled_args, i, [NumberNode.self])
        }

        let numbers = evaled_args.map({ $0 as! NumberNode })
        return numbers.dropFirst().reduce(numbers.first!, *)
    }

    func builtin_math_equal(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("=", args, (1, Int.max))
        let evaled_args = try eval_all(args, scope: scope)
        for i in 0..<args.count {
            try expect_type("=", evaled_args, i, [NumberNode.self])
        }

        let numbers = evaled_args.map({ ($0 as! NumberNode).value })
        let base = numbers.first!
        if numbers.dropFirst().contains(where: { $0 != base }) {
            return ListNode(elements: [])
        } else {
            return TRUE_VALUE
        }
    }

    func builtin_equal(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("equal", args, (2, Int.max))
        let evaled_args = try eval_all(args, scope: scope)

        let base = evaled_args.first!
        if evaled_args.dropFirst().contains(where: { $0 != base }) {
            return NIL_VALUE
        } else {
            return TRUE_VALUE
        }
    }

    func builtin_atom(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("atom", args, 1)

        let arg = try eval(args[0], scope: scope)
        guard let list = arg as? ListNode else {
            return TRUE_VALUE
        }

        return list.elements.count == 0 ? TRUE_VALUE : NIL_VALUE
    }

    func builtin_cons(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("atom", args, 2)
        let evaled_args = try eval_all(args, scope: scope)

        let head = [evaled_args[0]]

        switch evaled_args[1] {
        case let rest as ListNode:
            return ListNode(elements: head + rest.elements)
        default:
            return ListNode(elements: head + [evaled_args[1]])
        }
    }

    func builtin_car(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("car", args, 1)
        let evaled_args = try eval_all(args, scope: scope)
        try expect_type("car", evaled_args, 0, [ListNode.self])

        let list = evaled_args[0] as! ListNode

        return list.elements.count > 0 ? list.elements[0] : NIL_VALUE
    }

    func builtin_cdr(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("cdr", args, 1)
        let evaled_args = try eval_all(args, scope: scope)
        try expect_type("cdr", evaled_args, 0, [ListNode.self])

        let list = evaled_args[0] as! ListNode

        return ListNode(elements: Array<Node>(list.elements.dropFirst()))
    }

    func builtin_if(_ args: [Node], _ scope: Scope) throws -> Node {
        return NIL_VALUE
    }

    init() {
        self.globalScope = Scope()
        self.globalScope.define(NIL_NAME, NIL_VALUE)
        self.globalScope.define(TRUE_NAME, TRUE_VALUE)

        self.builtins["quote"]   = self.builtin_quote
        self.builtins["begin"]   = self.builtin_begin
        self.builtins["define"]  = self.builtin_define
        self.builtins["+"]       = self.builtin_math_add
        self.builtins["-"]       = self.builtin_math_sub
        self.builtins["/"]       = self.builtin_math_div
        self.builtins["*"]       = self.builtin_math_mul
        self.builtins["="]       = self.builtin_math_equal
        self.builtins["equal"]   = self.builtin_equal

        self.builtins["atom"]    = self.builtin_atom
        self.builtins["cons"]    = self.builtin_cons
        self.builtins["car"]     = self.builtin_car
        self.builtins["cdr"]     = self.builtin_cdr
        self.builtins["if"]      = self.builtin_if
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
