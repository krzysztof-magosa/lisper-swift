class InterpreterPlugin {
    var ip: Interpreter?

    func register(_ ip: Interpreter) {
        self.ip = ip
        afterRegister()
    }

    func afterRegister() {}
}

class InterpreterBuiltinsPlugin: InterpreterPlugin {
    typealias BuiltinType = ([Node], Scope) throws -> Node
    func index() -> [String: BuiltinType] {
        preconditionFailure("This method must be overridden.")
    }

    override func afterRegister() {
        for (k, v) in index() {
            self.ip!.builtins[k] = v
        }
    }

    // proxy to interpreter
    func eval(_ node: Node, scope: Scope) throws -> Node {
        return try self.ip!.eval(node, scope: scope)
    }

    // proxy to interpreter
    func eval_all(_ nodes: [Node], scope: Scope) throws -> [Node] {
        return try self.ip!.eval_all(nodes, scope: scope)
    }
}
