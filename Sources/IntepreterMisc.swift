class InterpreterMiscPlugin: InterpreterBuiltinsPlugin {
    override
    func index() -> [String: BuiltinType] {
        return [
          "define": fnDefine,
          "set": fnSet,
          "call": fnCall,
          "lambda": fnLambda,
          "macro": fnMacro,
          "list": fnList,
          "begin": fnBegin,
          "equal": fnEqual,
          "exists": fnExists,
          "null": fnNull,
          "atom": fnAtom,
          "join": fnJoin,
          "cons": fnCons,
          "car": fnCar,
          "cdr": fnCdr,
          "if": fnIf,
          "count": fnCount
        ]
    }

    func fnDefine(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("define", args, 2)
        try expect_type("define", args, 0, [SymbolNode.self])

        let name = args[0]
        let value = try eval(args[1], scope: scope)

        scope.define((name as! SymbolNode).name, value)
        return name
    }

    func fnSet(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("set!", args, 2)
        try expect_type("set!", args, 0, [SymbolNode.self])

        let name = args[0]
        let value = try eval(args[1], scope: scope)

        try scope.set((name as! SymbolNode).name, value)
        return name
    }

    func fnCall(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("call", args, 2)
        let name = try eval(args[0], scope: scope)
        try expect_type("call", [name], 0, [SymbolNode.self]) // @TODO it's hacky (list of args)

        return try eval(
          ListNode(elements: [name] + args.dropFirst()),
          scope: scope
        )
    }

    func fnLambda(_ args: [Node], _ scope: Scope) throws -> Node {
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

    func fnMacro(_ args: [Node], _ scope: Scope) throws -> Node {
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

    func fnList(_ args: [Node], _ scope: Scope) throws -> Node {
        let evaled_args = try ip!.eval_all(args, scope: scope)
        return ListNode(elements: Array(evaled_args))
    }

    func fnBegin(_ args: [Node], _ scope: Scope) throws -> Node {
        let evaled_args = try ip!.eval_all(args, scope: scope)
        return evaled_args.isEmpty ? NIL_VALUE : evaled_args.last!
    }

    func fnEqual(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("equal", args, (2, Int.max))
        let evaled_args = try ip!.eval_all(args, scope: scope)

        let base = evaled_args.first!
        if evaled_args.dropFirst().contains(where: { $0 != base }) {
            return NIL_VALUE
        } else {
            return TRUE_VALUE
        }
    }

    func fnExists(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("exists", args, 1)
        try expect_type("exists", args, 0, [SymbolNode.self])

        return (try scope.exists((args[0] as! SymbolNode).name)) ? TRUE_VALUE : NIL_VALUE
    }

    func fnNull(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("null", args, 1)

        let arg = try eval(args[0], scope: scope)
        return (arg == NIL_VALUE) ? TRUE_VALUE : NIL_VALUE
    }

    func fnAtom(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("atom", args, 1)
        let item = try eval(args[0], scope: scope)
        return isAtom(item) ? TRUE_VALUE : NIL_VALUE
    }

    func fnJoin(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("join", args, (2, Int.max))
        let evaled_args = try ip!.eval_all(args, scope: scope)
        for i in 0..<args.count {
            try expect_type("join", evaled_args, i, [ListNode.self])
        }

        let lists = evaled_args.map({ $0 as! ListNode })

        return lists.dropFirst().reduce(lists.first!, { $0 + $1})
    }

    func fnCons(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("atom", args, 2)
        let evaled_args = try ip!.eval_all(args, scope: scope)

        let head = [evaled_args[0]]

        switch evaled_args[1] {
        case let rest as ListNode:
            return ListNode(elements: head + rest.elements)
        default:
            return ListNode(elements: head + [evaled_args[1]])
        }
    }

    func fnCar(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("car", args, 1)
        let evaled_args = try ip!.eval_all(args, scope: scope)
        try expect_type("car", evaled_args, 0, [ListNode.self])

        let list = evaled_args[0] as! ListNode

        return list.elements.count > 0 ? list.elements[0] : NIL_VALUE
    }

    func fnCdr(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("cdr", args, 1)
        let evaled_args = try ip!.eval_all(args, scope: scope)
        try expect_type("cdr", evaled_args, 0, [ListNode.self])

        let list = evaled_args[0] as! ListNode

        return ListNode(elements: Array<Node>(list.elements.dropFirst()))
    }

    func fnIf(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("if", args, (2, 3))

        let expr = (try eval(args[0], scope: scope) != NIL_VALUE) ? 1 : 2
        if args.count > expr { // 0 is used for condition
            return try eval(args[expr], scope: scope)
        } else {
            return NIL_VALUE
        }
    }

    func fnCount(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("count", args, 1)
        let evaled_args = try ip!.eval_all(args, scope: scope)
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
}
