class InterpreterExtension {
    fileprivate var ip: Interpreter?

    func register(_ ip: Interpreter) {
        self.ip = ip
        afterRegister()
    }

    func afterRegister() {}
}

class InterpreterBuiltinsExtension: InterpreterExtension {
    typealias BuiltinType = ([Node], Scope) throws -> Node
    func index() -> [String: BuiltinType] {
        preconditionFailure("This method must be overridden.")
    }

    // proxy to interpreter
    func eval(_ node: Node, scope: Scope) throws -> Node {
        return try self.ip!.eval(node, scope: scope)
    }
}

class InterpreterMath: InterpreterBuiltinsExtension {
    override
    func index() -> [String: BuiltinType] {
        return [
          "+": self.add
        ]
    }

    func add(args: [Node], s: Scope) throws -> Node {
        return NumberNode(type: .integer, value: 5.0)
    }
}
