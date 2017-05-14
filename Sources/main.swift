import Foundation

print("LISPer - Swift implementation of LISP dialect")
print("(c) 2017 Krzysztof Magosa")
print("")

var interpreter = Interpreter()

var input: String?
repeat {
    do {
        print("LISPer> ", terminator: "")
        input = readLine()

        if input == nil {
            break
        }

        if input! == "" {
            continue
        }

        var lexer = Lexer(input: input!)
        var tokens = lexer.tokenize()

        var parser = Parser(input: tokens)
        var nodes = try parser.parse()

        var result = try interpreter.run(nodes[0])
        print(result)
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
        let lines = input!.components(separatedBy: .newlines)
        print(lines[position.line])
        print(String(repeating: " ", count: position.column) + "^")
        print("Parse error: unexpected token, got \(got) at \(position)")
    }
} while true
