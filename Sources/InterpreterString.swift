class InterpreterStringPlugin: InterpreterBuiltinsPlugin {
    override
    func index() -> [String: BuiltinType] {
        return [
          "to-symbol": fnToSymbol,
          "print": fnPrint,
          "concat": fnConcat,
          "char": fnChar,
          "upcase": fnUpcase,
          "downcase": fnDowncase
        ]
    }

    func fnToSymbol(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("to-symbol", args, 1)
        let evaled_args = try eval_all(args, scope: scope)
        try expect_type("to-symbol", evaled_args, 0, [StringNode.self])

        return SymbolNode(name: (evaled_args[0] as! StringNode).value)
    }

    func fnPrint(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("print", args, 1)
        let arg = try ip!.eval(args[0], scope: scope)
        print(arg)
        return arg
    }

    func fnConcat(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("concat", args, (1, Int.max))
        let evaled_args = try eval_all(args, scope: scope)
        for i in 0..<args.count {
            try expect_type("concat", evaled_args, i, [StringNode.self])
        }
        let strings = evaled_args.map({ $0 as! StringNode })

        return strings.reduce(StringNode(value: ""), { $0 + $1 })
    }

    func fnChar(_ args: [Node], _ scope: Scope) throws -> Node {
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

    func fnUpcase(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("upcase", args, 1)
        let evaled_args = try eval_all(args, scope: scope)
        try expect_type("char", evaled_args, 0, [StringNode.self])
        let string = (evaled_args[0] as! StringNode).value
        return StringNode(value: string.uppercased())
    }

    func fnDowncase(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("upcase", args, 1)
        let evaled_args = try eval_all(args, scope: scope)
        try expect_type("char", evaled_args, 0, [StringNode.self])
        let string = (evaled_args[0] as! StringNode).value
        return StringNode(value: string.lowercased())
    }
}
