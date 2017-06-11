enum InterpreterError: Error {
    case undefinedVariable(name: String)
    case invalidType(context: String, index: Int, got: Node.Type, expected: [Node.Type])
    case invalidNumberType(context: String, index: Int, got: NumberType, expected: NumberType)
    case nargs(context: String, got: Int, expected: (Int, Int))
    case notCallable(name: String)
    case illegalUse(name: String)
}

class Interpreter {
    var globalScope: Scope
    var builtins: [String: ([Node], Scope) throws -> (Node)] = [:]
    var plugins: [InterpreterPlugin] = []

    func registerPlugin(_ plugin: InterpreterPlugin) {
        plugins.append(plugin)
        plugin.register(self)
    }

    init() {
        self.globalScope = Scope()
        self.globalScope.define(NIL_NAME, NIL_VALUE)
        self.globalScope.define(TRUE_NAME, TRUE_VALUE)

        registerPlugin(InterpreterQuotePlugin())
        registerPlugin(InterpreterMiscPlugin())
        registerPlugin(InterpreterStringPlugin())
        registerPlugin(InterpreterMathPlugin())
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
