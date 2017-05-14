import Foundation

func run(_ input: String, using: Interpreter) throws -> Node? {
    do {
        let lexer = Lexer(input: input)
        let tokens = lexer.tokenize()

        let parser = Parser(input: tokens)
        let nodes = try parser.parse()

        return try using.run(nodes[0])
    } catch (InterpreterError.undefinedVariable(let name)) {
        print("undefined variable \(name)")
    } catch (InterpreterError.invalidType(let context, let index, let got, let expected)) {
        let types = expected.map({ $0.lispType }).joined(separator: "/")
        print("\(context): argument \(index): invalid type, got \(got.lispType), expected \(types)")
    } catch (InterpreterError.nargs(let context, let got, let expected)) {
        print("\(context): incorrect number of arguments, got \(got), expected \(expected.0)-\(expected.1)")
    } catch (InterpreterError.notCallable(let name)) {
        print("\(name) is not builtin/lambda so cannot be called")
    } catch (InterpreterError.illegalUse(let name)) {
        print("\(name) cannot be used like that")
    } catch (ParseError.unexpectedEOF) {
        print("Parse error: unexpected EOF")
    } catch (ParseError.unexpectedToken(let got, let position)) {
        let lines = input.components(separatedBy: .newlines)
        print(lines[position.line])
        print(String(repeating: " ", count: position.column) + "^")
        print("Parse error: unexpected token, got \(got) at \(position)")
    }

    return nil
}

//

let files = CommandLine.arguments.dropFirst()
let interpreter = Interpreter()
var input: String?

let stdlib = try String(contentsOfFile: "stdlib.lisper")
_ = try run(stdlib, using: interpreter)

if !files.isEmpty {
    input = try files.map({ try String(contentsOfFile: $0) }).joined(separator: "\n")
    _ = try run(input!, using: interpreter)
} else {
    print("LISPer - Swift implementation of LISP dialect")
    print("(c) 2017 Krzysztof Magosa")
    print("")

    repeat {
        print("LISPer> ", terminator: "")
        input = readLine()

        // Ctrl+D
        if input == nil {
            break
        }

        if input! == "" {
            continue
        }

        if let result = try run(input!, using: interpreter) {
            print(result)
        }
    } while true
}
