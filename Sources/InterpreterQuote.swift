class InterpreterQuotePlugin: InterpreterBuiltinsPlugin {
    override
    func index() -> [String: BuiltinType] {
        return [
          "unquote": self.fnUnquote,
          "quote": self.fnQuote,
          "quasiquote": self.fnQuasiquote
        ]
    }

    func expandQuasiquote(_ item: Node) -> Node {
        if isAtom(item) {
            return ListNode(
              elements: [
                SymbolNode(name: "quote"),
                item
              ]
            )
        } else {
            let list = item as! ListNode

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

    func fnUnquote(_ args: [Node], _ scope: Scope) throws -> Node {
        throw InterpreterError.illegalUse(name: "unquote")
    }

    func fnQuote(_ args: [Node], _ scope: Scope) throws -> Node {
        return args[0]
    }

    func fnQuasiquote(_ args: [Node], _ scope: Scope) throws -> Node {
        // @TODO validation
        return try eval(
          expandQuasiquote(args[0]),
          scope: scope
        )
    }
}
