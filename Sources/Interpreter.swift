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
    case invalidNumberType(context: String, index: Int, got: NumberType, expected: NumberType)
    case nargs(context: String, got: Int, expected: (Int, Int))
    case notCallable(name: String)
    case illegalUse(name: String)
}

class Scope {
    var data: [String: Node]
    var parent: Scope?

    init(parameters: [String] = [], arguments: [Node] = [], parent: Scope? = nil) {
        self.data = [:]

        for (k, v) in zip(parameters, arguments) {
            self.data[k] = v
        }

        self.parent = parent
    }

    func exists(_ name: String) throws -> Bool {
        do {
            _ = try findScope(name)
        } catch InterpreterError.undefinedVariable {
            return false
        }

        return true
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

func expect_ntype(_ context: String, _ args: [Node], _ index: Int, _ type: NumberType) throws {
    try expect_type(context, args, index, [NumberNode.self])
    let n = args[index] as! NumberNode

    if n.type != type {
        throw InterpreterError.invalidNumberType(context: context, index: index, got: n.type, expected: type)
    }
}

class Interpreter {
    var globalScope: Scope
    var builtins: [String: ([Node], Scope) throws -> (Node)] = [:]

    func expandQuasiquote(_ item: Node) -> Node {
        if isAtom(item) {
            return ListNode(
              elements: [
                SymbolNode(name: "quote"),
                item
              ]
            )
        } else {
            let list = item as! ListNode // hmm

            if list.elements[0] == SymbolNode(name: "unquote") {
                return list.elements[1]
            } else {
                return ListNode(
                  elements: [
                    SymbolNode(name: "cons"),
                    expandQuasiquote(list.elements[0]),
                    expandQuasiquote(ListNode(elements: Array(list.elements.dropFirst())))
                  ]
                )
            }
        }
    }

    func builtin_unquote(_ args: [Node], _ scope: Scope) throws -> Node {
        throw InterpreterError.illegalUse(name: "unquote")
    }

    func builtin_quote(_ args: [Node], _ scope: Scope) throws -> Node {
        return args[0]
    }

    func builtin_quasiquote(_ args: [Node], _ scope: Scope) throws -> Node {
        // @TODO walidacja
        return try eval(
          expandQuasiquote(args[0]),
          scope: scope
        )
    }

    func builtin_list(_ args: [Node], _ scope: Scope) throws -> Node {
        let evaled_args = try eval_all(args, scope: scope)
        return ListNode(elements: Array(evaled_args))
    }

    func builtin_begin(_ args: [Node], _ scope: Scope) throws -> Node {
        let evaled_args = try eval_all(args, scope: scope)
        return evaled_args.isEmpty ? NIL_VALUE : evaled_args.last!
    }

    func builtin_define(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("define", args, 2)
        try expect_type("define", args, 0, [SymbolNode.self])

        let name = args[0]
        let value = try eval(args[1], scope: scope)

        scope.define((name as! SymbolNode).name, value)
        return name
    }

    func builtin_set(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("set!", args, 2)
        try expect_type("set!", args, 0, [SymbolNode.self])

        let name = args[0]
        let value = try eval(args[1], scope: scope)

        try scope.set((name as! SymbolNode).name, value)
        return name
    }

    func builtin_call(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("call", args, 2)
        let name = try eval(args[0], scope: scope)
        try expect_type("call", [name], 0, [SymbolNode.self]) // @TODO it's hacky (list of args)

        return try eval(
          ListNode(elements: [name] + args.dropFirst()),
          scope: scope
        )
    }

    func builtin_lambda(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("lambda", args, 2)
        try expect_type("lambda", args, 0, [ListNode.self])

        let parameters = (args[0] as! ListNode).elements

        for i in 0..<parameters.count {
            try expect_type("lambda::parameters", parameters, i, [SymbolNode.self])
        }

        return LambdaNode(
          parameters: parameters.map { ($0 as! SymbolNode).name },
          body: args[1],
          parentScope: scope
        )
    }

    func builtin_macro(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("macro", args, 2)
        try expect_type("macro", args, 0, [ListNode.self])

        let parameters = (args[0] as! ListNode).elements

        for i in 0..<parameters.count {
            try expect_type("macro::parameters", parameters, i, [SymbolNode.self])
        }

        return MacroNode(
          parameters: parameters.map { ($0 as! SymbolNode).name },
          body: args[1],
          parentScope: scope
        )
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

    func builtin_math_rem(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("rem", args, 2)
        let evaled_args = try eval_all(args, scope: scope)
        for i in 0..<args.count {
            try expect_type("*", evaled_args, i, [NumberNode.self])
        }

        let numbers = evaled_args.map({ $0 as! NumberNode })
        return numbers[0].rem(numbers[1])
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

    func builtin_math_comp(_ args: [Node], _ scope: Scope, label: String, op: (NumberNode, NumberNode) -> Bool) throws -> Node {
        try expect_nargs(label, args, (1, Int.max))
        let evaled_args = try eval_all(args, scope: scope)
        for i in 0..<args.count {
            try expect_type(label, evaled_args, i, [NumberNode.self])
        }

        let numbers = evaled_args.map({ $0 as! NumberNode })

        for i in 0..<numbers.count-1 {
            if !op(numbers[i], numbers[i+1]) {
                return NIL_VALUE
            }
        }

        return TRUE_VALUE
    }

    func builtin_math_lt(_ args: [Node], _ scope: Scope) throws -> Node {
        return try builtin_math_comp(args, scope, label: "<", op: <)
    }

    func builtin_math_le(_ args: [Node], _ scope: Scope) throws -> Node {
        return try builtin_math_comp(args, scope, label: "<=", op: <=)
    }

    func builtin_math_gt(_ args: [Node], _ scope: Scope) throws -> Node {
        return try builtin_math_comp(args, scope, label: ">", op: >)
    }

    func builtin_math_ge(_ args: [Node], _ scope: Scope) throws -> Node {
        return try builtin_math_comp(args, scope, label: ">=", op: >=)
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

    func builtin_exists(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("exists", args, 1)
        try expect_type("exists", args, 0, [SymbolNode.self])

        return (try scope.exists((args[0] as! SymbolNode).name)) ? TRUE_VALUE : NIL_VALUE
    }

    func builtin_null(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("null", args, 1)

        let arg = try eval(args[0], scope: scope)
        return (arg == NIL_VALUE) ? TRUE_VALUE : NIL_VALUE
    }

    func isAtom(_ item: Node) -> Bool {
        guard let list = item as? ListNode else {
            return true
        }

        return list.elements.count == 0
    }

    func builtin_atom(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("atom", args, 1)
        let item = try eval(args[0], scope: scope)
        return isAtom(item) ? TRUE_VALUE : NIL_VALUE
    }

    func builtin_join(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("join", args, (2, Int.max))
        let evaled_args = try eval_all(args, scope: scope)
        for i in 0..<args.count {
            try expect_type("join", evaled_args, i, [ListNode.self])
        }

        let lists = evaled_args.map({ $0 as! ListNode })

        return lists.dropFirst().reduce(lists.first!, { $0 + $1})
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
        try expect_nargs("if", args, (2, 3))

        let expr = (try eval(args[0], scope: scope) != NIL_VALUE) ? 1 : 2
        if args.count > expr { // 0 is used for condition
            return try eval(args[expr], scope: scope)
        } else {
            return NIL_VALUE
        }
    }

    func builtin_to_symbol(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("to-symbol", args, 1)
        let evaled_args = try eval_all(args, scope: scope)
        try expect_type("to-symbol", evaled_args, 0, [StringNode.self])

        return SymbolNode(name: (evaled_args[0] as! StringNode).value)
    }

    func builtin_print(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("print", args, 1)
        let arg = try eval(args[0], scope: scope)
        print(arg)
        return arg
    }

    func builtin_concat(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("concat", args, (1, Int.max))
        let evaled_args = try eval_all(args, scope: scope)
        for i in 0..<args.count {
            try expect_type("concat", evaled_args, i, [StringNode.self])
        }
        let strings = evaled_args.map({ $0 as! StringNode })

        return strings.reduce(StringNode(value: ""), { $0 + $1 })
    }

    func builtin_char(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("char", args, 2)
        let evaled_args = try eval_all(args, scope: scope)
        try expect_type("char", evaled_args, 0, [StringNode.self])
        try expect_ntype("char", evaled_args, 1, .integer)

        let string = (evaled_args[0] as! StringNode).value
        let n = Int((evaled_args[1] as! NumberNode).value)

        let characters = Array(string.characters)

        if n >= 0 && n < characters.count {
            return StringNode(value: String(characters[n]))
        } else {
            return NIL_VALUE
        }
    }

    func builtin_upcase(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("upcase", args, 1)
        let evaled_args = try eval_all(args, scope: scope)
        try expect_type("char", evaled_args, 0, [StringNode.self])
        let string = (evaled_args[0] as! StringNode).value
        return StringNode(value: string.uppercased())
    }

    func builtin_downcase(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("upcase", args, 1)
        let evaled_args = try eval_all(args, scope: scope)
        try expect_type("char", evaled_args, 0, [StringNode.self])
        let string = (evaled_args[0] as! StringNode).value
        return StringNode(value: string.lowercased())
    }

    func builtin_count(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("count", args, 1)
        let evaled_args = try eval_all(args, scope: scope)
        try expect_type("count", evaled_args, 0, [ListNode.self, StringNode.self])

        var result: Int
        switch evaled_args[0] {
        case let s as StringNode:
            result = Array(s.value.characters).count
        case let l as ListNode:
            result = l.elements.count
        default:
            result = 0
        }

        return NumberNode(type: .integer, value: Double(result))
    }

    init() {
        self.globalScope = Scope()
        self.globalScope.define(NIL_NAME, NIL_VALUE)
        self.globalScope.define(TRUE_NAME, TRUE_VALUE)

        self.builtins["unquote"]    = self.builtin_unquote
        self.builtins["quote"]      = self.builtin_quote
        self.builtins["quasiquote"] = self.builtin_quasiquote
        self.builtins["list"]       = self.builtin_list
        self.builtins["begin"]      = self.builtin_begin
        self.builtins["lambda"]     = self.builtin_lambda
        self.builtins["macro"]      = self.builtin_macro
        self.builtins["define"]     = self.builtin_define
        self.builtins["set!"]       = self.builtin_set
        self.builtins["call"]       = self.builtin_call

        self.builtins["+"]          = self.builtin_math_add
        self.builtins["-"]          = self.builtin_math_sub
        self.builtins["/"]          = self.builtin_math_div
        self.builtins["*"]          = self.builtin_math_mul
        self.builtins["rem"]        = self.builtin_math_rem
        self.builtins["="]          = self.builtin_math_equal
        self.builtins["<"]          = self.builtin_math_lt
        self.builtins["<="]         = self.builtin_math_le
        self.builtins[">"]          = self.builtin_math_gt
        self.builtins[">="]         = self.builtin_math_ge

        self.builtins["equal"]      = self.builtin_equal
        self.builtins["exists"]     = self.builtin_exists
        self.builtins["null"]       = self.builtin_null
        self.builtins["atom"]       = self.builtin_atom
        self.builtins["join"]       = self.builtin_join
        self.builtins["cons"]       = self.builtin_cons
        self.builtins["car"]        = self.builtin_car
        self.builtins["cdr"]        = self.builtin_cdr
        self.builtins["if"]         = self.builtin_if
        self.builtins["to-symbol"]  = self.builtin_to_symbol
        self.builtins["print"]      = self.builtin_print
        self.builtins["concat"]     = self.builtin_concat
        self.builtins["char"]       = self.builtin_char
        self.builtins["upcase"]     = self.builtin_upcase
        self.builtins["downcase"]   = self.builtin_downcase
        self.builtins["count"]      = self.builtin_count
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
                    let something = try eval(s, scope: scope)

                    switch something {
                    case let lambda as LambdaNode:
                        let arguments = try eval_all(Array(l.elements.dropFirst()), scope: scope)
                        return try lambda.call(arguments: arguments, using: self)
                    case let macro as MacroNode:
                        let lisp = try macro.call(
                          arguments: Array(l.elements.dropFirst()),
                          using: self
                        )

                        return try eval(lisp, scope: scope)
                    default:
                        throw InterpreterError.notCallable(name: s.name)
                    }
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
