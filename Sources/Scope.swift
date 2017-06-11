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
