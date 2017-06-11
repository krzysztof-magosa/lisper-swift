func inferNumberType(_ args: [NumberNode]) -> NumberType {
    for arg in args {
        if arg.type == .float {
            return .float
        }
    }

    return .integer // default
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

func isAtom(_ item: Node) -> Bool {
    guard let list = item as? ListNode else {
        return true
    }

    return list.elements.count == 0
}
