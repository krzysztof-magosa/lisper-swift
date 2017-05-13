var interpreter = Interpreter()

var input: String?
repeat {
    print("LISPer> ", terminator: "")
    var input = readLine()

    if input == nil {
        break
    }

    var lexer = Lexer(input: input!)
    var tokens = lexer.tokenize()

    var parser = Parser(input: tokens)
    var nodes = try parser.parse()

    var result = try interpreter.run(nodes[0])
    dump(result)
} while true
