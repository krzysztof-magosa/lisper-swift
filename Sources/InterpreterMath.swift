class InterpreterMathPlugin: InterpreterBuiltinsPlugin {
    override
    func index() -> [String: BuiltinType] {
        return [
          "+": fnAdd,
          "-": fnSub,
          "/": fnDiv,
          "*": fnMul,
          "rem": fnRem,
          "=": fnEqual,
          "<": fnLt,
          "<=": fnLe,
          ">": fnGt,
          ">=": fnGe
        ]
    }

    func fnAdd(_ args: [Node], _ scope: Scope) throws -> Node {
        let evaled_args = try eval_all(args, scope: scope)
        for i in 0..<args.count {
            try expect_type("+", evaled_args, i, [NumberNode.self])
        }

        let numbers = evaled_args.map({ $0 as! NumberNode })
        return numbers.reduce(NumberNode(type: .integer, value: 0), +)
    }

    func fnSub(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("-", args, (2, Int.max))
        let evaled_args = try eval_all(args, scope: scope)
        for i in 0..<args.count {
            try expect_type("-", evaled_args, i, [NumberNode.self])
        }

         let numbers = evaled_args.map({ $0 as! NumberNode })
         return numbers.dropFirst().reduce(numbers.first!, -)
    }

    func fnDiv(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("/", args, (2, Int.max))
        let evaled_args = try eval_all(args, scope: scope)
        for i in 0..<args.count {
            try expect_type("/", evaled_args, i, [NumberNode.self])
        }

        let numbers = evaled_args.map({ $0 as! NumberNode })
        return numbers.dropFirst().reduce(numbers.first!, /)
    }

    func fnMul(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("*", args, (1, Int.max))
        let evaled_args = try eval_all(args, scope: scope)
        for i in 0..<args.count {
            try expect_type("*", evaled_args, i, [NumberNode.self])
        }

        let numbers = evaled_args.map({ $0 as! NumberNode })
        return numbers.dropFirst().reduce(numbers.first!, *)
    }

    func fnRem(_ args: [Node], _ scope: Scope) throws -> Node {
        try expect_nargs("rem", args, 2)
        let evaled_args = try eval_all(args, scope: scope)
        for i in 0..<args.count {
            try expect_type("*", evaled_args, i, [NumberNode.self])
        }

        let numbers = evaled_args.map({ $0 as! NumberNode })
        return numbers[0].rem(numbers[1])
    }


    func fnEqual(_ args: [Node], _ scope: Scope) throws -> Node {
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

    func fnLt(_ args: [Node], _ scope: Scope) throws -> Node {
        return try comp(args, scope, label: "<", op: <)
    }

    func fnLe(_ args: [Node], _ scope: Scope) throws -> Node {
        return try comp(args, scope, label: "<=", op: <=)
    }

    func fnGt(_ args: [Node], _ scope: Scope) throws -> Node {
        return try comp(args, scope, label: ">", op: >)
    }

    func fnGe(_ args: [Node], _ scope: Scope) throws -> Node {
        return try comp(args, scope, label: ">=", op: >=)
    }

    // helper
    func comp(_ args: [Node], _ scope: Scope, label: String, op: (NumberNode, NumberNode) -> Bool) throws -> Node {
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
}
